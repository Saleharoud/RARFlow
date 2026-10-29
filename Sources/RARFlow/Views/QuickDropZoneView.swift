import SwiftUI
import UniformTypeIdentifiers

public struct QuickDropZoneView: View {
    @Bindable var appState: AppState
    @State private var isTargeted: Bool = false

    public var body: some View {
        VStack(spacing: 28) {
            // Main Drop Target Box
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(
                        isTargeted ? RARFlowTheme.accentCyan : RARFlowTheme.borderMedium,
                        style: StrokeStyle(lineWidth: isTargeted ? 2.5 : 1.5, dash: [8, 6])
                    )
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(isTargeted ? RARFlowTheme.accentBlue.opacity(0.12) : RARFlowTheme.bgPill)
                    )

                VStack(spacing: 18) {
                    ZStack {
                        Circle()
                            .fill(isTargeted ? RARFlowTheme.accentCyan.opacity(0.15) : RARFlowTheme.bgPillActive)
                            .frame(width: 80, height: 80)

                        Image(systemName: isTargeted ? "arrow.down.circle.fill" : "tray.and.arrow.down.fill")
                            .font(.system(size: 42))
                            .foregroundStyle(isTargeted ? RARFlowTheme.accentCyan : RARFlowTheme.accentBlue)
                            .scaleEffect(isTargeted ? 1.15 : 1.0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isTargeted)
                    }

                    VStack(spacing: 8) {
                        Text(isTargeted ? "Release to Open or Compress!" : "Drop Archives or Files Here")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(RARFlowTheme.textPrimary)

                        Text("Drop any **RAR, 7Z, ZIP, or TAR** archive to inspect or extract it.\nDrop **files or folders** to compress them into an archive.")
                            .font(.system(size: 13))
                            .foregroundStyle(RARFlowTheme.textSecondary)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: 440)
                    }

                    HStack(spacing: 14) {
                        Button {
                            appState.chooseArchiveFileToOpen()
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "archivebox.fill")
                                Text("Open Archive...")
                            }
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(RARFlowTheme.textPrimary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(RARFlowTheme.bgPillActive)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(RARFlowTheme.borderActive, lineWidth: 1)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                        .buttonStyle(.plain)

                        Button {
                            let panel = NSOpenPanel()
                            panel.canChooseFiles = true
                            panel.canChooseDirectories = true
                            panel.allowsMultipleSelection = true
                            panel.prompt = "Choose"
                            panel.message = "Select files or folders to compress"
                            if panel.runModal() == .OK {
                                appState.startCompressWizard(with: panel.urls)
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "doc.zipper")
                                Text("Compress Files...")
                            }
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(RARFlowTheme.accentBlue)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .shadow(color: RARFlowTheme.accentBlue.opacity(0.35), radius: 8, x: 0, y: 3)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.top, 4)
                }
                .padding(36)
            }
            .frame(maxWidth: 640, maxHeight: 370)
            .onDrop(of: [.fileURL], isTargeted: $isTargeted) { providers in
                handleDroppedProviders(providers)
            }

            // Format Badges Grid
            VStack(spacing: 10) {
                Text("SUPPORTED FORMATS")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(RARFlowTheme.textMuted)
                    .tracking(1.2)

                HStack(spacing: 8) {
                    formatTag(name: "RAR / RAR5 / RAR7", isExtractOnly: true)
                    formatTag(name: "7-Zip (.7z)", isExtractOnly: false)
                    formatTag(name: "ZIP (.zip)", isExtractOnly: false)
                    formatTag(name: "TAR / GZ / XZ", isExtractOnly: false)
                    formatTag(name: "ISO / DMG", isExtractOnly: true)
                }
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(RARFlowTheme.bgWindow)
    }

    private func formatTag(name: String, isExtractOnly: Bool) -> some View {
        HStack(spacing: 4) {
            Text(name)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(RARFlowTheme.textSecondary)

            if isExtractOnly {
                Text("(Extract)")
                    .font(.system(size: 9))
                    .foregroundStyle(RARFlowTheme.textMuted)
            }
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 4)
        .background(RARFlowTheme.bgPill)
        .overlay(
            RoundedRectangle(cornerRadius: 5)
                .stroke(RARFlowTheme.borderSubtle, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 5))
    }

    private func handleDroppedProviders(_ providers: [NSItemProvider]) -> Bool {
        final class URLCollector: @unchecked Sendable {
            private let lock = NSLock()
            private var items: [URL] = []
            func append(_ url: URL) {
                lock.lock()
                defer { lock.unlock() }
                items.append(url)
            }
            var all: [URL] {
                lock.lock()
                defer { lock.unlock() }
                return items
            }
        }

        let collector = URLCollector()
        let group = DispatchGroup()

        for provider in providers {
            group.enter()
            _ = provider.loadObject(ofClass: URL.self) { url, _ in
                if let url = url {
                    collector.append(url)
                }
                group.leave()
            }
        }

        group.notify(queue: .main) {
            let dropped = collector.all
            guard !dropped.isEmpty else { return }

            if dropped.count == 1, let singleURL = dropped.first {
                if let _ = ArchiveFormat.detect(from: singleURL) {
                    // It's an archive: open in browser
                    self.appState.openArchive(url: singleURL)
                    return
                }
            }

            // Otherwise, it's regular files or folders to compress
            self.appState.startCompressWizard(with: dropped)
        }

        return true
    }
}
