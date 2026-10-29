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
                        .fill(RARFlowTheme.accentBlue.opacity(0.18))
                        .frame(width: 54, height: 54)
                    Image(systemName: "archivebox.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(RARFlowTheme.accentCyan)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Extract Archive?")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(RARFlowTheme.textPrimary)
                    Text("Do you want to extract **\(archiveName)**?")
                        .font(.system(size: 13))
                        .foregroundStyle(RARFlowTheme.textSecondary)
                }

                Spacer()
            }

            // Info Card
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("File Size:")
                        .font(.caption.bold())
                        .foregroundStyle(RARFlowTheme.textMuted)
                        .frame(width: 90, alignment: .leading)
                    Text(fileSizeString.isEmpty ? "Unknown" : fileSizeString)
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(RARFlowTheme.textPrimary)
                }

                HStack {
                    Text("Format:")
                        .font(.caption.bold())
                        .foregroundStyle(RARFlowTheme.textMuted)
                        .frame(width: 90, alignment: .leading)
                    Text(targetURL.flatMap { ArchiveFormat.detect(from: $0) }?.displayName ?? "Compressed Archive")
                        .font(.caption)
                        .foregroundStyle(RARFlowTheme.textPrimary)
                }

                HStack {
                    Text("Extract To:")
                        .font(.caption.bold())
                        .foregroundStyle(RARFlowTheme.textMuted)
                        .frame(width: 90, alignment: .leading)
                    Text(plannedDestinationFolder.path)
                        .font(.caption)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .foregroundStyle(RARFlowTheme.textSecondary)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RARFlowTheme.bgPill)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(RARFlowTheme.borderSubtle, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))

            // Remember checkbox
            Toggle("Always perform this action without asking", isOn: $rememberPreference)
                .font(.system(size: 12))
                .foregroundStyle(RARFlowTheme.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Divider()
                .background(RARFlowTheme.borderSubtle)

            // Action Buttons
            HStack(spacing: 10) {
                Button("Cancel") {
                    appState.showExtractPromptDialog = false
                    appState.pendingOpenURL = nil
                }
                .buttonStyle(.plain)
                .foregroundStyle(RARFlowTheme.textSecondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(RARFlowTheme.bgPill)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button("Browse Files") {
                    handleBrowse()
                }
                .buttonStyle(.plain)
                .foregroundStyle(RARFlowTheme.textPrimary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(RARFlowTheme.bgPillActive)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(RARFlowTheme.borderActive, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .help("Open and view archive contents without extracting")

                Button("Extract To...") {
                    handleExtractTo()
                }
                .buttonStyle(.plain)
                .foregroundStyle(RARFlowTheme.textPrimary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(RARFlowTheme.bgPillActive)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(RARFlowTheme.borderActive, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 6))

                Button("Extract Now") {
                    handleExtractNow()
                }
                .buttonStyle(.plain)
                .foregroundStyle(.white)
                .font(.system(size: 13, weight: .bold))
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .background(RARFlowTheme.accentBlue)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .shadow(color: RARFlowTheme.accentBlue.opacity(0.35), radius: 6, x: 0, y: 2)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 500)
        .background(RARFlowTheme.bgWindow)
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
