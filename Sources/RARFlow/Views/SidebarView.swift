import SwiftUI
import AppKit

public struct SidebarView: View {
    @Bindable var appState: AppState

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    // Quick Access Section
                    VStack(alignment: .leading, spacing: 3) {
                        sectionTitle("QUICK ACCESS")

                        sidebarItem(
                            title: "Drop Zone",
                            systemIcon: "tray.and.arrow.down.fill",
                            isSelected: appState.selectedSection == .dropZone,
                            accentColor: RARFlowTheme.accentCyan
                        ) {
                            appState.selectedSection = .dropZone
                        }

                        sidebarItem(
                            title: "Archive Browser",
                            systemIcon: "folder.fill",
                            isSelected: appState.selectedSection == .browser,
                            hasDotBadge: appState.activeArchiveURL != nil,
                            accentColor: RARFlowTheme.accentBlue
                        ) {
                            appState.selectedSection = .browser
                        }

                        sidebarButton(
                            title: "New Archive...",
                            systemIcon: "plus.circle.fill",
                            accentColor: RARFlowTheme.accentBlue
                        ) {
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

                        sidebarItem(
                            title: "Settings",
                            systemIcon: "gearshape.fill",
                            isSelected: appState.selectedSection == .settings,
                            accentColor: RARFlowTheme.textMuted
                        ) {
                            appState.selectedSection = .settings
                        }
                    }

                    // Recents Section
                    if !appState.recentArchives.isEmpty {
                        VStack(alignment: .leading, spacing: 3) {
                            sectionTitle("RECENTS")

                            ForEach(appState.recentArchives, id: \.self) { url in
                                Button {
                                    appState.openArchive(url: url)
                                } label: {
                                    HStack(spacing: 8) {
                                        Image(systemName: "shippingbox.fill")
                                            .font(.system(size: 11))
                                            .foregroundStyle(RARFlowTheme.accentAmber)

                                        Text(url.lastPathComponent)
                                            .font(.system(size: 12))
                                            .foregroundStyle(appState.activeArchiveURL == url ? RARFlowTheme.textPrimary : RARFlowTheme.textSecondary)
                                            .lineLimit(1)
                                            .truncationMode(.middle)

                                        Spacer(minLength: 0)
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(appState.activeArchiveURL == url ? RARFlowTheme.bgPillActive : Color.clear)
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                                }
                                .buttonStyle(.plain)
                                .contextMenu {
                                    Button("Open in RARFlow") {
                                        appState.openArchive(url: url)
                                    }
                                    Button("Reveal in Finder") {
                                        NSWorkspace.shared.activateFileViewerSelecting([url])
                                    }
                                    Divider()
                                    Button("Remove from Recents") {
                                        appState.recentArchives.removeAll(where: { $0 == url })
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 14)
            }

            Spacer(minLength: 0)
        }
        .frame(width: 195)
        .background(RARFlowTheme.bgSidebar)
        .overlay(
            Rectangle()
                .frame(width: 1)
                .foregroundStyle(RARFlowTheme.borderSubtle),
            alignment: .trailing
        )
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(RARFlowTheme.textMuted)
            .tracking(1.2)
            .padding(.horizontal, 10)
            .padding(.top, 4)
            .padding(.bottom, 2)
    }

    private func sidebarItem(
        title: String,
        systemIcon: String,
        isSelected: Bool,
        hasDotBadge: Bool = false,
        accentColor: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: systemIcon)
                    .font(.system(size: 12))
                    .foregroundStyle(isSelected ? RARFlowTheme.accentCyan : accentColor)
                    .frame(width: 16)

                Text(title)
                    .font(.system(size: 12, weight: isSelected ? .semibold : .medium))
                    .foregroundStyle(isSelected ? RARFlowTheme.accentCyan : RARFlowTheme.textSecondary)

                Spacer(minLength: 0)

                if hasDotBadge {
                    Circle()
                        .fill(RARFlowTheme.dotGreen)
                        .frame(width: 7, height: 7)
                        .shadow(color: RARFlowTheme.dotGreen.opacity(0.8), radius: 3)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(isSelected ? RARFlowTheme.bgSidebarActive : Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(isSelected ? RARFlowTheme.borderSidebarActive : Color.clear, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
    }

    private func sidebarButton(
        title: String,
        systemIcon: String,
        accentColor: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: systemIcon)
                    .font(.system(size: 12))
                    .foregroundStyle(accentColor)
                    .frame(width: 16)

                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(RARFlowTheme.textSecondary)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
    }
}
