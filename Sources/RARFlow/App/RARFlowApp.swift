import SwiftUI
import AppKit

final class ServiceProvider: NSObject, @unchecked Sendable {
    weak var appState: AppState?

    @objc func extractSelection(_ pboard: NSPasteboard, userData: String, error: AutoreleasingUnsafeMutablePointer<NSString?>) {
        let urls = extractURLs(from: pboard)
        guard let first = urls.first else { return }
        let state = self.appState
        Task { @MainActor in
            state?.handleFileOpenRequest(url: first)
        }
    }

    @objc func compressSelection(_ pboard: NSPasteboard, userData: String, error: AutoreleasingUnsafeMutablePointer<NSString?>) {
        let urls = extractURLs(from: pboard)
        guard !urls.isEmpty else { return }
        let state = self.appState
        Task { @MainActor in
            state?.startCompressWizard(with: urls)
        }
    }

    private func extractURLs(from pboard: NSPasteboard) -> [URL] {
        if let urls = pboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL], !urls.isEmpty {
            return urls
        }
        if let filenames = pboard.propertyList(forType: .init("NSFilenamesPboardType")) as? [String] {
            return filenames.map { URL(fileURLWithPath: $0) }
        }
        return []
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate, @unchecked Sendable {
    weak var appState: AppState? {
        didSet {
            serviceProvider.appState = appState
        }
    }
    var initialLaunchURL: URL?
    private let serviceProvider = ServiceProvider()

    func applicationDidFinishLaunching(_ notification: Notification) {
        serviceProvider.appState = appState
        NSApplication.shared.servicesProvider = serviceProvider
        NSUpdateDynamicServices()
    }

    func application(_ application: NSApplication, openFiles filenames: [String]) {
        guard let first = filenames.first else { return }
        let url = URL(fileURLWithPath: first)
        if let state = appState {
            Task { @MainActor in
                state.handleFileOpenRequest(url: url)
            }
        } else {
            initialLaunchURL = url
        }
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        guard let first = urls.first else { return }
        if let state = appState {
            Task { @MainActor in
                state.handleFileOpenRequest(url: first)
            }
        } else {
            initialLaunchURL = first
        }
    }
}

@main
struct RARFlowApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            MainView(appState: appState)
                .frame(minWidth: 800, minHeight: 520)
                .onAppear {
                    appDelegate.appState = appState
                    if let initial = appDelegate.initialLaunchURL {
                        appDelegate.initialLaunchURL = nil
                        appState.handleFileOpenRequest(url: initial)
                    } else {
                        // Check CLI arguments
                        let args = CommandLine.arguments
                        if args.count > 1 {
                            let argPath = args[1]
                            if !argPath.hasPrefix("-") && FileManager.default.fileExists(atPath: argPath) {
                                let url = URL(fileURLWithPath: argPath)
                                appState.handleFileOpenRequest(url: url)
                            }
                        }
                    }
                }
                .onOpenURL { url in
                    appState.handleFileOpenRequest(url: url)
                }
        }
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Open Archive...") {
                    appState.chooseArchiveFileToOpen()
                }
                .keyboardShortcut("o", modifiers: [.command])

                Button("New Archive...") {
                    let panel = NSOpenPanel()
                    panel.canChooseFiles = true
                    panel.canChooseDirectories = true
                    panel.allowsMultipleSelection = true
                    panel.prompt = "Select"
                    panel.message = "Select files or folders to compress"
                    if panel.runModal() == .OK {
                        appState.startCompressWizard(with: panel.urls)
                    }
                }
                .keyboardShortcut("n", modifiers: [.command])

                Divider()

                Button("Extract All") {
                    appState.extractAll()
                }
                .keyboardShortcut("e", modifiers: [.command])
                .disabled(appState.activeArchiveURL == nil)

                Button("Test Archive Integrity") {
                    appState.testCurrentArchive()
                }
                .keyboardShortcut("t", modifiers: [.command])
                .disabled(appState.activeArchiveURL == nil)
            }
        }

        #if os(macOS)
        Settings {
            SettingsView(appState: appState)
                .frame(width: 540, height: 500)
        }
        #endif
    }
}
