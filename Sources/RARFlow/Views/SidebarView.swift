import SwiftUI

public struct SidebarView: View {
    @Bindable var appState: AppState

    public var body: some View {
        List(selection: $appState.selectedSection) {
            Section("Quick Access") {
                NavigationLink(value: AppSidebarSection.dropZone) {
                    Label(AppSidebarSection.dropZone.rawValue, systemImage: AppSidebarSection.dropZone.iconName)
                }

                NavigationLink(value: AppSidebarSection.browser) {
                    HStack {
                        Label(AppSidebarSection.browser.rawValue, systemImage: AppSidebarSection.browser.iconName)
                        Spacer()
                        if appState.activeArchiveURL != nil {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 8, height: 8)
                        }
                    }
                }

                Button {
                    let panel = NSOpenPanel()
                    panel.canChooseFiles = true
                    panel.canChooseDirectories = true
                    panel.allowsMultipleSelection = true
                    panel.prompt = "Select"
                    panel.message = "Select files or folders to compress"
                    if panel.runModal() == .OK {
                        appState.startCompressWizard(with: panel.urls)
                    }
                } label: {
                    Label("New Archive...", systemImage: "plus.circle.fill")
                }
                .buttonStyle(.plain)

                NavigationLink(value: AppSidebarSection.settings) {
                    Label(AppSidebarSection.settings.rawValue, systemImage: AppSidebarSection.settings.iconName)
                }
            }

            if !appState.recentArchives.isEmpty {
                Section("Recent Archives") {
                    ForEach(appState.recentArchives, id: \.self) { url in
                        Button {
                            appState.openArchive(url: url)
                        } label: {
                            HStack {
                                Image(systemName: "doc.zipper")
                                    .foregroundStyle(.secondary)
                                Text(url.lastPathComponent)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                            }
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button("Open in RARFlow") {
                                appState.openArchive(url: url)
                            }
                            Button("Reveal in Finder") {
                                NSWorkspace.shared.activateFileViewerSelecting([url])
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .frame(minWidth: 200)
    }
}
