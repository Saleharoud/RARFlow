import Foundation
import SwiftUI
import AppKit

public enum AppSidebarSection: String, CaseIterable, Identifiable, Sendable {
    case dropZone = "Drop Zone"
    case browser = "Archive Browser"
    case newArchive = "New Archive"
    case settings = "Settings"

    public var id: String { rawValue }

    public var iconName: String {
        switch self {
        case .dropZone: return "arrow.down.doc.fill"
        case .browser: return "folder.badge.gearshape"
        case .newArchive: return "plus.circle.fill"
        case .settings: return "gearshape.fill"
        }
    }
}

@Observable
@MainActor
public final class AppState {
    public var selectedSection: AppSidebarSection = .dropZone
    public var activeArchiveURL: URL?
    public var archiveMetadata: ArchiveMetadata?
    public var archiveItems: [ArchiveItem] = []
    public var selectedItemIDs: Set<String> = []
    public var searchQuery: String = ""
    public var isFlatView: Bool = false
    public var currentFolderPrefix: String = "" // For hierarchical navigation

    // Progress & Operations
    public var isBusy: Bool = false
    public var busyTitle: String = ""
    public var progress: Double = 0.0
    public var progressDetail: String = ""

    // Modals & Sheets
    public var pendingOpenURL: URL?
    public var showExtractPromptDialog: Bool = false

    public var showPasswordPrompt: Bool = false
    public var passwordPromptTitle: String = "Password Required"
    public var pendingPasswordAction: (@MainActor (String) -> Void)?

    public var showCompressSheet: Bool = false
    public var compressSourceURLs: [URL] = []

    public var showSettingsSheet: Bool = false
    public var showInfoSheet: Bool = false

    // Alerts
    public var errorMessage: String? {
        didSet { showErrorAlert = errorMessage != nil }
    }
    public var showErrorAlert: Bool = false

    public var alertMessage: String?
    public var showAlert: Bool = false

    // Recents
    public var recentArchives: [URL] = []

    // Settings
    public var extractionSettings = ExtractionSettings()
    public var compressionSettings = CompressionSettings()

    public init() {
        loadRecents()
    }

    // MARK: - Filtered Items
    public var displayedItems: [ArchiveItem] {
        var items = archiveItems

        if !searchQuery.isEmpty {
            items = items.filter {
                $0.filename.localizedCaseInsensitiveContains(searchQuery) ||
                $0.path.localizedCaseInsensitiveContains(searchQuery)
            }
        } else if !isFlatView {
            // Hierarchical mode: filter items belonging to the current folder level
            let prefix = currentFolderPrefix
            items = items.filter { item in
                if prefix.isEmpty {
                    // Root level: items without slashes, or first level folders
                    let path = item.path
                    if let firstSlash = path.firstIndex(of: "/") {
                        let topDir = String(path[...firstSlash])
                        return item.path == topDir || (item.isDirectory && item.path == String(path[..<firstSlash]))
                    }
                    return true
                } else {
                    guard item.path.hasPrefix(prefix) && item.path != prefix else { return false }
                    let sub = String(item.path.dropFirst(prefix.count))
                    if let firstSlash = sub.firstIndex(of: "/") {
                        let directChildFolder = prefix + String(sub[...firstSlash])
                        return item.path == directChildFolder
                    }
                    return true
                }
            }
        }

        return items.sorted {
            if $0.isDirectory != $1.isDirectory {
                return $0.isDirectory && !$1.isDirectory
            }
            return $0.filename.localizedStandardCompare($1.filename) == .orderedAscending
        }
    }

    // MARK: - Handle External File Open (from Finder, CLI, Dock)
    public func handleFileOpenRequest(url: URL) {
        if ArchiveFormat.detect(from: url) != nil {
            let action = UserDefaults.standard.string(forKey: "onArchiveOpenAction") ?? "ask"
            switch action {
            case "extract":
                self.activeArchiveURL = url
                self.extractAll(customDestination: nil)
            case "browse":
                self.openArchive(url: url)
            default: // "ask"
                self.pendingOpenURL = url
                self.showExtractPromptDialog = true
            }
        } else {
            // Not an archive: open compression wizard
            self.startCompressWizard(with: [url])
        }
    }

    // MARK: - Open Archive
    public func openArchive(url: URL, password: String? = nil) {
        Task {
            self.isBusy = true
            self.busyTitle = "Reading Archive..."
            self.progress = 0.0
            self.progressDetail = url.lastPathComponent

            do {
                let (meta, items) = try await ArchiveEngine.shared.listArchive(url: url, password: password)
                self.activeArchiveURL = url
                self.archiveMetadata = meta
                self.archiveItems = items
                self.selectedItemIDs.removeAll()
                self.currentFolderPrefix = ""
                self.selectedSection = .browser
                self.addToRecents(url: url)
            } catch ArchiveError.passwordRequired {
                self.promptForPassword(title: "Archive is Encrypted") { [weak self] enteredPassword in
                    self?.openArchive(url: url, password: enteredPassword)
                }
            } catch {
                self.errorMessage = error.localizedDescription
            }

            self.isBusy = false
        }
    }

    // MARK: - Extract All
    public func extractAll(customDestination: URL? = nil) {
        guard let archiveURL = activeArchiveURL else { return }

        let dest: URL
        if let custom = customDestination {
            dest = custom
        } else if let chosen = chooseDestinationFolder() {
            dest = chosen
        } else {
            return
        }

        performExtraction(archiveURL: archiveURL, items: nil, destination: dest)
    }

    // MARK: - Extract Selected
    public func extractSelected(customDestination: URL? = nil) {
        guard let archiveURL = activeArchiveURL else { return }
        let selected = archiveItems.filter { selectedItemIDs.contains($0.id) }
        guard !selected.isEmpty else {
            self.errorMessage = "Please select at least one file or folder to extract."
            return
        }

        let dest: URL
        if let custom = customDestination {
            dest = custom
        } else if let chosen = chooseDestinationFolder() {
            dest = chosen
        } else {
            return
        }

        performExtraction(archiveURL: archiveURL, items: selected, destination: dest)
    }

    private func performExtraction(archiveURL: URL, items: [ArchiveItem]?, destination: URL, password: String? = nil) {
        Task {
            self.isBusy = true
            self.busyTitle = "Extracting \(archiveURL.lastPathComponent)..."
            self.progress = 0.0
            self.progressDetail = "Starting extraction..."

            do {
                let extractedDest = try await ArchiveEngine.shared.extractArchive(
                    url: archiveURL,
                    items: items,
                    destination: destination,
                    settings: self.extractionSettings,
                    password: password
                ) { [weak self] pct, item in
                    Task { @MainActor in
                        self?.progress = pct
                        self?.progressDetail = item
                    }
                }

                if self.extractionSettings.playSound {
                    NSSound(named: "Glass")?.play()
                }
                if self.extractionSettings.revealInFinder {
                    NSWorkspace.shared.activateFileViewerSelecting([extractedDest])
                }
            } catch ArchiveError.passwordRequired, ArchiveError.wrongPassword {
                self.promptForPassword(title: "Enter Extraction Password") { [weak self] enteredPwd in
                    self?.performExtraction(archiveURL: archiveURL, items: items, destination: destination, password: enteredPwd)
                }
            } catch {
                self.errorMessage = error.localizedDescription
            }

            self.isBusy = false
        }
    }

    // MARK: - Quick Look Spacebar Preview
    public func quickLookSelectedItem() {
        guard let archiveURL = activeArchiveURL,
              let selectedID = selectedItemIDs.first,
              let item = archiveItems.first(where: { $0.id == selectedID }),
              !item.isDirectory else { return }

        Task {
            self.isBusy = true
            self.busyTitle = "Loading Preview..."
            self.progress = 0.5
            self.progressDetail = item.filename

            do {
                let previewURL = try await ArchiveEngine.shared.extractSingleItemForPreview(
                    archiveURL: archiveURL,
                    item: item
                )
                QuickLookPreviewController.shared.preview(fileURL: previewURL, title: item.filename)
            } catch {
                self.errorMessage = "Could not preview: \(error.localizedDescription)"
            }

            self.isBusy = false
        }
    }

    // MARK: - Test Archive
    public func testCurrentArchive() {
        guard let archiveURL = activeArchiveURL else { return }

        Task {
            self.isBusy = true
            self.busyTitle = "Testing Archive Integrity..."
            self.progress = 0.5
            self.progressDetail = "Verifying checksums and headers..."

            do {
                let ok = try await ArchiveEngine.shared.testArchiveIntegrity(url: archiveURL)
                if ok {
                    self.alertMessage = "Integrity check passed! No errors were found in \(archiveURL.lastPathComponent)."
                } else {
                    self.errorMessage = "Integrity check failed. The archive may be corrupt or incomplete."
                }
                self.showAlert = true
            } catch {
                self.errorMessage = error.localizedDescription
            }

            self.isBusy = false
        }
    }

    // MARK: - Compression Actions
    public func startCompressWizard(with sources: [URL]) {
        guard !sources.isEmpty else { return }
        self.compressSourceURLs = sources
        self.showCompressSheet = true
    }

    public func executeCompression(destination: URL, settings: CompressionSettings) {
        let sources = self.compressSourceURLs
        guard !sources.isEmpty else { return }
        self.showCompressSheet = false

        Task {
            self.isBusy = true
            self.busyTitle = "Creating Archive..."
            self.progress = 0.0
            self.progressDetail = destination.lastPathComponent

            do {
                try await ArchiveEngine.shared.compressFiles(
                    sources: sources,
                    destination: destination,
                    settings: settings
                ) { [weak self] pct, detail in
                    Task { @MainActor in
                        self?.progress = pct
                        self?.progressDetail = detail
                    }
                }
                self.alertMessage = "Successfully created archive:\n\(destination.lastPathComponent)"
                self.showAlert = true
                if self.extractionSettings.revealInFinder {
                    NSWorkspace.shared.activateFileViewerSelecting([destination])
                }
            } catch {
                self.errorMessage = error.localizedDescription
            }

            self.isBusy = false
        }
    }

    public func cancelCurrentOperation() {
        Task {
            await ArchiveEngine.shared.cancelActiveOperation()
            self.isBusy = false
            self.progress = 0.0
            self.progressDetail = ""
        }
    }

    // MARK: - Password Prompt Helper
    public func promptForPassword(title: String, completion: @escaping @MainActor (String) -> Void) {
        self.passwordPromptTitle = title
        self.pendingPasswordAction = completion
        self.showPasswordPrompt = true
    }

    // MARK: - Folder Picker
    public func chooseDestinationFolder() -> URL? {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Extract Here"
        panel.message = "Choose destination folder for extraction"
        if panel.runModal() == .OK {
            return panel.url
        }
        return nil
    }

    public func chooseArchiveFileToOpen() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.prompt = "Open"
        panel.message = "Select an archive file to open"
        if panel.runModal() == .OK, let url = panel.url {
            self.openArchive(url: url)
        }
    }

    // MARK: - Recents
    private func loadRecents() {
        if let stored = UserDefaults.standard.array(forKey: "RARFlow_Recents") as? [String] {
            self.recentArchives = stored.compactMap { URL(string: $0) }
        }
    }

    private func addToRecents(url: URL) {
        var recents = self.recentArchives.filter { $0 != url }
        recents.insert(url, at: 0)
        if recents.count > 10 {
            recents = Array(recents.prefix(10))
        }
        self.recentArchives = recents
        UserDefaults.standard.set(recents.map { $0.absoluteString }, forKey: "RARFlow_Recents")
    }
}
