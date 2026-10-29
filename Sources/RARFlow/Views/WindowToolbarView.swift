import SwiftUI
import AppKit

public struct WindowToolbarView: View {
    @Bindable var appState: AppState

    public var body: some View {
        HStack(spacing: 12) {
            // View Mode Switcher: Browser | Drop Zone
            HStack(spacing: 2) {
                toolbarTabButton(
                    title: "Browser",
                    systemImage: "folder.fill",
                    isSelected: appState.selectedSection == .browser
                ) {
                    appState.selectedSection = .browser
                }

                toolbarTabButton(
                    title: "Drop Zone",
                    systemImage: "tray.and.arrow.down.fill",
                    isSelected: appState.selectedSection == .dropZone
                ) {
                    appState.selectedSection = .dropZone
                }
            }
            .padding(2)
            .background(Color.black.opacity(0.20))
            .overlay(
                RoundedRectangle(cornerRadius: 7)
                    .stroke(RARFlowTheme.borderSubtle, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 7))

            // Center Search Box
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(RARFlowTheme.textMuted)

                TextField(
                    "",
                    text: $appState.searchQuery,
                    prompt: Text(appState.activeArchiveURL == nil ? "Search files..." : "Search \(appState.archiveItems.count) files...")
                        .foregroundStyle(RARFlowTheme.textMuted)
                )
                .textFieldStyle(.plain)
                .font(.system(size: 12))
                .foregroundStyle(RARFlowTheme.textPrimary)

                if !appState.searchQuery.isEmpty {
                    Button {
                        appState.searchQuery = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(RARFlowTheme.textMuted)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .frame(minWidth: 180, maxWidth: 260)
            .background(RARFlowTheme.bgInput)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(RARFlowTheme.borderSubtle, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 6))

            Spacer()

            // Right Action Buttons
            HStack(spacing: 8) {
                // Quick Look
                Button {
                    appState.quickLookSelectedItem()
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "eye.fill")
                            .font(.system(size: 11))
                        Text("Quick Look")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(RARFlowTheme.bgInput)
                    .foregroundStyle(appState.selectedItemIDs.isEmpty ? RARFlowTheme.textMuted : RARFlowTheme.textPrimary)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(RARFlowTheme.borderSubtle, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
                .disabled(appState.selectedItemIDs.isEmpty)
                .help("Preview selected file with Quick Look (Space)")

                // Test Integrity
                Button {
                    appState.testCurrentArchive()
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "checkmark.shield.fill")
                            .font(.system(size: 11))
                        Text("Test Integrity")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(RARFlowTheme.bgInput)
                    .foregroundStyle(appState.activeArchiveURL == nil ? RARFlowTheme.textMuted : RARFlowTheme.textPrimary)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(RARFlowTheme.borderSubtle, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
                .disabled(appState.activeArchiveURL == nil)
                .help("Test archive integrity and checksums")

                // Extract Selected
                Button {
                    appState.extractSelected()
                } label: {
                    Text("Extract Selected\(appState.selectedItemIDs.isEmpty ? "" : " (\(appState.selectedItemIDs.count))")")
                        .font(.system(size: 12, weight: .medium))
                        .padding(.horizontal, 11)
                        .padding(.vertical, 5)
                        .background(RARFlowTheme.bgInput)
                        .foregroundStyle(appState.selectedItemIDs.isEmpty ? RARFlowTheme.textMuted : RARFlowTheme.textPrimary)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(RARFlowTheme.borderSubtle, lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
                .disabled(appState.selectedItemIDs.isEmpty)

                // Extract All
                Button {
                    appState.extractAll()
                } label: {
                    Text("Extract All")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 5)
                        .background(appState.activeArchiveURL == nil ? Color.gray.opacity(0.3) : RARFlowTheme.accentBlue)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .shadow(color: appState.activeArchiveURL == nil ? .clear : RARFlowTheme.accentBlue.opacity(0.35), radius: 6, x: 0, y: 2)
                }
                .buttonStyle(.plain)
                .disabled(appState.activeArchiveURL == nil)
                .keyboardShortcut("e", modifiers: [.command])
            }
        }
        .padding(.horizontal, 14)
        .frame(height: 44)
        .background(RARFlowTheme.bgToolbar)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundStyle(RARFlowTheme.borderSubtle),
            alignment: .bottom
        )
    }

    private func toolbarTabButton(title: String, systemImage: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: systemImage)
                    .font(.system(size: 11))
                Text(title)
                    .font(.system(size: 12, weight: isSelected ? .semibold : .medium))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(isSelected ? RARFlowTheme.bgPillActive : Color.clear)
            .foregroundStyle(isSelected ? RARFlowTheme.textPrimary : RARFlowTheme.textSecondary)
            .overlay(
                RoundedRectangle(cornerRadius: 5)
                    .stroke(isSelected ? RARFlowTheme.borderActive : Color.clear, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 5))
        }
        .buttonStyle(.plain)
    }
}
