import SwiftUI

public struct SettingsView: View {
    @Bindable var appState: AppState
    @AppStorage("defaultExtractionFolderMode") private var folderMode: String = "ask"
    @AppStorage("onArchiveOpenAction") private var openAction: String = "ask"
    @AppStorage("customRarBinaryPath") private var customRarPath: String = ""
    @State private var finderActionsInstalled: Bool = {
        let path = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Services/Extract using RARFlow.workflow")
        return FileManager.default.fileExists(atPath: path.path)
    }()

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Section: Extraction
                VStack(alignment: .leading, spacing: 14) {
                    Text("EXTRACTION PREFERENCES")
                        .font(.caption2.bold())
                        .foregroundStyle(.secondary)
                        .tracking(1.0)

                    Picker("When Opening Archive:", selection: $openAction) {
                        Text("Show extraction dialog (Ask each time)").tag("ask")
                        Text("Extract immediately").tag("extract")
                        Text("Browse contents in app").tag("browse")
                    }

                    Picker("Extract Destination:", selection: $folderMode) {
                        Text("Ask every time").tag("ask")
                        Text("Same folder as archive").tag("same")
                        Text("Downloads folder").tag("downloads")
                        Text("Desktop").tag("desktop")
                    }

                    Picker("File Overwrite Policy:", selection: $appState.extractionSettings.overwritePolicy) {
                        ForEach(OverwritePolicy.allCases) { policy in
                            Text(policy.rawValue).tag(policy)
                        }
                    }

                    Toggle("Create subfolder for archive contents", isOn: $appState.extractionSettings.createSubfolder)
                    Toggle("Reveal extracted files in Finder upon completion", isOn: $appState.extractionSettings.revealInFinder)
                    Toggle("Play notification sound on completion", isOn: $appState.extractionSettings.playSound)
                    Toggle("Move archive to Trash after successful extraction", isOn: $appState.extractionSettings.deleteArchiveAfter)
                }

                Divider()

                // Section: Finder Context Menu Integration
                VStack(alignment: .leading, spacing: 14) {
                    Text("FINDER RIGHT-CLICK CONTEXT MENU")
                        .font(.caption2.bold())
                        .foregroundStyle(.secondary)
                        .tracking(1.0)

                    Text("Enables **'Extract using RARFlow'** and **'Compress using RARFlow'** directly in Finder's right-click context menu and Quick Actions.")
                        .font(.callout)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 12) {
                        Button {
                            installFinderActions()
                        } label: {
                            Label(finderActionsInstalled ? "Reinstall Finder Quick Actions" : "Enable Finder Right-Click Actions", systemImage: "macwindow.badge.plus")
                        }
                        .buttonStyle(.borderedProminent)

                        if finderActionsInstalled {
                            Label("Installed in Finder", systemImage: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                                .font(.callout)
                        }
                    }
                }

                Divider()

                // Section: Compression
                VStack(alignment: .leading, spacing: 14) {
                    Text("COMPRESSION DEFAULTS")
                        .font(.caption2.bold())
                        .foregroundStyle(.secondary)
                        .tracking(1.0)

                    Toggle("Automatically exclude macOS system files (.DS_Store, __MACOSX)", isOn: $appState.compressionSettings.excludeMacMetadata)
                    Toggle("Enable solid archiving by default for 7Z", isOn: $appState.compressionSettings.isSolid)

                    HStack {
                        Text("CPU Threads for Compression:")
                        Stepper("\(appState.compressionSettings.threadCount) cores", value: $appState.compressionSettings.threadCount, in: 1...ProcessInfo.processInfo.activeProcessorCount)
                    }
                }

                Divider()

                // Section: Engine & Helper Tools
                VStack(alignment: .leading, spacing: 14) {
                    Text("ENGINE & HELPER TOOLS")
                        .font(.caption2.bold())
                        .foregroundStyle(.secondary)
                        .tracking(1.0)

                    helperStatusRow(name: "7-Zip Engine (7zz)", url: HelperLocator.findSevenZip())
                    helperStatusRow(name: "The Unarchiver Tool (lsar)", url: HelperLocator.findLsar())
                    helperStatusRow(name: "The Unarchiver Tool (unar)", url: HelperLocator.findUnar())

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Custom WinRAR 'rar' CLI Binary (Optional for RAR creation):")
                            .font(.callout)
                        HStack {
                            TextField("Path to /usr/local/bin/rar", text: $customRarPath)
                                .textFieldStyle(.roundedBorder)
                            Button("Browse...") {
                                let panel = NSOpenPanel()
                                panel.canChooseFiles = true
                                panel.canChooseDirectories = false
                                panel.prompt = "Select"
                                if panel.runModal() == .OK, let url = panel.url {
                                    customRarPath = url.path
                                }
                            }
                        }
                    }
                }
            }
            .padding(28)
        }
        .background(RARFlowTheme.bgWindow)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func helperStatusRow(name: String, url: URL?) -> some View {
        HStack {
            Image(systemName: url != nil ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundStyle(url != nil ? .green : .red)
            Text(name)
                .bold()
            Spacer()
            if let path = url?.path {
                Text(path)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            } else {
                Text("Not Installed")
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
    }

    private func installFinderActions() {
        let scriptURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("scripts/install_finder_services.sh")
        let scriptPath: String
        if FileManager.default.fileExists(atPath: scriptURL.path) {
            scriptPath = scriptURL.path
        } else if let bundleScript = Bundle.main.path(forResource: "install_finder_services", ofType: "sh") {
            scriptPath = bundleScript
        } else {
            scriptPath = "/bin/bash"
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        process.arguments = [scriptPath]
        try? process.run()
        process.waitUntilExit()

        finderActionsInstalled = true
        appState.alertMessage = "Finder Quick Actions successfully installed!\n\nYou can now right-click any file in Finder and select 'Extract using RARFlow' or 'Compress using RARFlow'."
        appState.showAlert = true
    }
}
