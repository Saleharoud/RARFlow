import SwiftUI
import UniformTypeIdentifiers

public struct QuickDropZoneView: View {
    @Bindable var appState: AppState
    @State private var isTargeted: Bool = false

    public var body: some View {
        VStack(spacing: 32) {
            // Main Drop Target Box
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(
                        isTargeted ? Color.accentColor : Color.secondary.opacity(0.35),
                        style: StrokeStyle(lineWidth: isTargeted ? 3 : 2, dash: [8, 6])
                    )
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(isTargeted ? Color.accentColor.opacity(0.08) : Color(nsColor: .controlBackgroundColor).opacity(0.4))
                    )

                VStack(spacing: 18) {
                    Image(systemName: isTargeted ? "arrow.down.circle.fill" : "arrow.down.doc")
                        .font(.system(size: 64))
                        .foregroundStyle(isTargeted ? Color.accentColor : Color.secondary)
                        .scaleEffect(isTargeted ? 1.15 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isTargeted)

                    VStack(spacing: 6) {
                        Text(isTargeted ? "Drop Files Here!" : "Drop Archives or Files Here")
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("Drop any **RAR, 7Z, ZIP, or TAR** archive to inspect or extract it.\nDrop **files or folders** to compress them into an archive.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: 440)
                    }

                    HStack(spacing: 16) {
                        Button {
                            appState.chooseArchiveFileToOpen()
                        } label: {
                            Label("Open Archive...", systemImage: "archivebox")
                        }
                        .controlSize(.large)

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
                            Label("Compress Files...", systemImage: "doc.zipper")
                        }
                        .controlSize(.large)
                        .buttonStyle(.borderedProminent)
                    }
                    .padding(.top, 8)
                }
                .padding(40)
            }
            .frame(maxWidth: 650, maxHeight: 380)
            .onDrop(of: [.fileURL], isTargeted: $isTargeted) { providers in
                handleDroppedProviders(providers)
            }

            // Format Badge Grid
            VStack(spacing: 10) {
                Text("SUPPORTED FORMATS")
                    .font(.caption2.bold())
                    .foregroundStyle(.secondary)
                    .tracking(1.2)

                HStack(spacing: 10) {
                    formatTag(name: "RAR / RAR5", isExtractOnly: true)
                    formatTag(name: "7-Zip (.7z)", isExtractOnly: false)
                    formatTag(name: "ZIP (.zip)", isExtractOnly: false)
                    formatTag(name: "TAR / GZ / XZ", isExtractOnly: false)
                    formatTag(name: "ISO / DMG", isExtractOnly: true)
                }
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func formatTag(name: String, isExtractOnly: Bool) -> some View {
        HStack(spacing: 4) {
            Text(name)
                .font(.caption.bold())
            if isExtractOnly {
                Text("(Extract)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
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
