import SwiftUI
import AppKit

public struct ExtractPromptSheetView: View {
    @Bindable var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @AppStorage("onArchiveOpenAction") private var openAction: String = "ask"
    @State private var rememberPreference: Bool = false

    private var targetURL: URL? {
        appState.pendingOpenURL
    }

    private var archiveName: String {
        targetURL?.lastPathComponent ?? "Archive"
    }

    private var fileSizeString: String {
        guard let url = targetURL,
              let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
              let size = attrs[.size] as? NSNumber else {
            return ""
        }
        return ByteCountFormatter.string(fromByteCount: size.int64Value, countStyle: .file)
    }

    private var plannedDestinationFolder: URL {
        guard let url = targetURL else {
            return FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!
        }
        let folderMode = UserDefaults.standard.string(forKey: "defaultExtractionFolderMode") ?? "same"
        switch folderMode {
        case "downloads":
            return FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!
        case "desktop":
            return FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first!
        default:
            return url.deletingLastPathComponent()
        }
    }

    public var body: some View {
        VStack(spacing: 20) {
            // Header with Icon
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.accentColor.opacity(0.12))
                        .frame(width: 56, height: 56)
                    Image(systemName: "archivebox.circle.fill")
                        .font(.system(size: 34))
                        .foregroundStyle(.tint)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Extract Archive?")
                        .font(.title3.bold())
                    Text("Do you want to extract **\(archiveName)**?")
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                }

                Spacer()
            }

            // Info Card
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("File Size:")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                        .frame(width: 90, alignment: .leading)
                    Text(fileSizeString.isEmpty ? "Unknown" : fileSizeString)
                        .font(.caption)
                }

                HStack {
                    Text("Format:")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                        .frame(width: 90, alignment: .leading)
                    Text(targetURL.flatMap { ArchiveFormat.detect(from: $0) }?.displayName ?? "Compressed Archive")
                        .font(.caption)
                }

                HStack {
                    Text("Extract To:")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                        .frame(width: 90, alignment: .leading)
                    Text(plannedDestinationFolder.path)
                        .font(.caption)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(nsColor: .controlBackgroundColor))
            )

            // Remember checkbox
            Toggle("Always perform this action without asking", isOn: $rememberPreference)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Divider()

            // Action Buttons
            HStack(spacing: 10) {
                Button("Cancel") {
                    appState.showExtractPromptDialog = false
                    appState.pendingOpenURL = nil
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button("Browse Files") {
                    handleBrowse()
                }
                .help("Open and view archive contents without extracting")

                Button("Extract To...") {
                    handleExtractTo()
                }

                Button("Extract Now") {
                    handleExtractNow()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 500)
    }

    private func handleExtractNow() {
        if rememberPreference {
            openAction = "extract"
        }
        guard let url = targetURL else { return }
        appState.showExtractPromptDialog = false
        appState.pendingOpenURL = nil
        appState.activeArchiveURL = url
        appState.extractAll(customDestination: plannedDestinationFolder)
    }

    private func handleExtractTo() {
        guard let url = targetURL else { return }
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true
        panel.prompt = "Extract Here"
        panel.message = "Choose destination folder for \(url.lastPathComponent)"

        if panel.runModal() == .OK, let chosen = panel.url {
            appState.showExtractPromptDialog = false
            appState.pendingOpenURL = nil
            appState.activeArchiveURL = url
            appState.extractAll(customDestination: chosen)
        }
    }

    private func handleBrowse() {
        if rememberPreference {
            openAction = "browse"
        }
        guard let url = targetURL else { return }
        appState.showExtractPromptDialog = false
        appState.pendingOpenURL = nil
        appState.openArchive(url: url)
    }
}
