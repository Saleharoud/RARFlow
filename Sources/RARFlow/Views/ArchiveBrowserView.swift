import SwiftUI
import AppKit

public struct ArchiveBrowserView: View {
    @Bindable var appState: AppState
    @State private var sortOrder = [KeyPathComparator(\ArchiveItem.filename)]

    public var body: some View {
        VStack(spacing: 0) {
            if let activeURL = appState.activeArchiveURL {
                // Top archive header bar
                archiveHeaderBar(activeURL: activeURL)
                Divider()

                // File Table
                if appState.displayedItems.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "folder.badge.questionmark")
                            .font(.system(size: 40))
                            .foregroundStyle(.secondary)
                        Text(appState.searchQuery.isEmpty ? "This folder is empty" : "No matches found for '\(appState.searchQuery)'")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    fileTable
                }

                Divider()
                // Bottom Status Bar
                bottomStatusBar
            } else {
                noArchivePlaceholder
            }
        }
        .searchable(text: $appState.searchQuery, placement: .toolbar, prompt: "Search files in archive")
        .sheet(isPresented: $appState.showInfoSheet) {
            if let meta = appState.archiveMetadata {
                ArchiveInfoSheet(metadata: meta)
            }
        }
    }

    // MARK: - Header Bar
    private func archiveHeaderBar(activeURL: URL) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "archivebox.fill")
                .foregroundStyle(.tint)
                .font(.title3)

            VStack(alignment: .leading, spacing: 2) {
                Text(activeURL.lastPathComponent)
                    .font(.headline)
                    .lineLimit(1)
                HStack(spacing: 8) {
                    if !appState.currentFolderPrefix.isEmpty {
                        Button {
                            navigateUp()
                        } label: {
                            Label("Up", systemImage: "arrow.up.left")
                        }
                        .buttonStyle(.accessoryBar)

                        Text(appState.currentFolderPrefix)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text(appState.archiveMetadata?.formatName ?? "Archive")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            // Flat / Tree Toggle
            Toggle(isOn: $appState.isFlatView) {
                Label("Flat View", systemImage: appState.isFlatView ? "list.bullet.rectangle" : "folder")
            }
            .toggleStyle(.button)
            .help("Toggle between hierarchical folder view and flat list of all files")

            // Quick Look Button
            Button {
                appState.quickLookSelectedItem()
            } label: {
                Label("Quick Look", systemImage: "eye")
            }
            .keyboardShortcut(.space, modifiers: [])
            .disabled(appState.selectedItemIDs.isEmpty)
            .help("Preview selected file with Quick Look (Space)")

            // Test Integrity
            Button {
                appState.testCurrentArchive()
            } label: {
                Label("Test", systemImage: "checkmark.shield")
            }
            .help("Test archive integrity and checksums")

            // Info
            Button {
                appState.showInfoSheet = true
            } label: {
                Label("Info", systemImage: "info.circle")
            }
            .help("View archive technical details")

            // Extract Selected
            Button {
                appState.extractSelected()
            } label: {
                Label("Extract Selected\(appState.selectedItemIDs.isEmpty ? "" : " (\(appState.selectedItemIDs.count))")", systemImage: "arrow.down.doc")
            }
            .disabled(appState.selectedItemIDs.isEmpty)

            // Extract All
            Button {
                appState.extractAll()
            } label: {
                Label("Extract All", systemImage: "arrow.down.circle.fill")
            }
            .buttonStyle(.borderedProminent)
            .keyboardShortcut("e", modifiers: [.command])
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(nsColor: .controlBackgroundColor))
    }

    // MARK: - File Table
    private var fileTable: some View {
        Table(appState.displayedItems, selection: $appState.selectedItemIDs, sortOrder: $sortOrder) {
            TableColumn("Name") { item in
                HStack(spacing: 8) {
                    Image(systemName: item.systemIconName)
                        .foregroundStyle(item.isDirectory ? Color.accentColor : Color.secondary)
                        .frame(width: 18)

                    Text(item.filename)
                        .fontWeight(item.isDirectory ? .medium : .regular)

                    if item.isEncrypted {
                        Image(systemName: "lock.fill")
                            .font(.caption2)
                            .foregroundStyle(.yellow)
                    }
                }
                .contextMenu {
                    tableItemContextMenu(item: item)
                }
            }
            .width(min: 220, ideal: 300)

            TableColumn("Size") { item in
                Text(item.humanReadableSize)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            .width(min: 70, ideal: 90)

            TableColumn("Packed") { item in
                Text(item.humanReadableCompressedSize)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            .width(min: 70, ideal: 90)

            TableColumn("Ratio") { item in
                Text(item.compressionRatioString)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            .width(min: 60, ideal: 70)

            TableColumn("Date Modified") { item in
                Text(item.formattedDate)
                    .foregroundStyle(.secondary)
            }
            .width(min: 130, ideal: 150)

            TableColumn("CRC32") { item in
                Text(item.crc32 ?? "--")
                    .foregroundStyle(.tertiary)
                    .font(.caption.monospaced())
            }
            .width(min: 80, ideal: 90)
        }
        .onDoubleClick {
            handleDoubleClick()
        }
    }

    private func handleDoubleClick() {
        guard let selectedID = appState.selectedItemIDs.first,
              let item = appState.archiveItems.first(where: { $0.id == selectedID }) else { return }

        if item.isDirectory {
            if !appState.isFlatView {
                let folder = item.path.hasSuffix("/") ? item.path : item.path + "/"
                appState.currentFolderPrefix = folder
            }
        } else {
            appState.quickLookSelectedItem()
        }
    }

    private func navigateUp() {
        var current = appState.currentFolderPrefix
        if current.hasSuffix("/") { current.removeLast() }
        if let lastSlash = current.lastIndex(of: "/") {
            appState.currentFolderPrefix = String(current[...lastSlash])
        } else {
            appState.currentFolderPrefix = ""
        }
    }

    @ViewBuilder
    private func tableItemContextMenu(item: ArchiveItem) -> some View {
        Button("Extract This Item...") {
            appState.selectedItemIDs = [item.id]
            appState.extractSelected()
        }

        if !item.isDirectory {
            Button("Quick Look Preview (Space)") {
                appState.selectedItemIDs = [item.id]
                appState.quickLookSelectedItem()
            }
        }

        Divider()

        Button("Copy Path") {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(item.path, forType: .string)
        }
        Button("Copy File Name") {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(item.filename, forType: .string)
        }
    }

    // MARK: - Status Bar
    private var bottomStatusBar: some View {
        HStack(spacing: 16) {
            Text("\(appState.displayedItems.count) items")
                .foregroundStyle(.secondary)

            if let meta = appState.archiveMetadata {
                Text("•")
                    .foregroundStyle(.tertiary)
                Text("Uncompressed: \(meta.humanReadableUncompressedSize)")
                    .foregroundStyle(.secondary)
                Text("•")
                    .foregroundStyle(.tertiary)
                Text("Compressed: \(meta.humanReadablePhysicalSize)")
                    .foregroundStyle(.secondary)
                Text("•")
                    .foregroundStyle(.tertiary)
                Text("Ratio: \(meta.overallRatioString)")
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if !appState.selectedItemIDs.isEmpty {
                Text("\(appState.selectedItemIDs.count) selected")
                    .foregroundStyle(.tint)
            }
        }
        .font(.caption)
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    // MARK: - No Archive Placeholder
    private var noArchivePlaceholder: some View {
        VStack(spacing: 20) {
            Image(systemName: "archivebox")
                .font(.system(size: 64))
                .foregroundStyle(.tertiary)

            VStack(spacing: 6) {
                Text("No Archive Loaded")
                    .font(.title2)
                    .fontWeight(.semibold)
                Text("Open a RAR, 7Z, ZIP, or TAR archive to browse its contents, or switch to Drop Zone to extract.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 400)
            }

            HStack(spacing: 12) {
                Button {
                    appState.chooseArchiveFileToOpen()
                } label: {
                    Label("Open Archive...", systemImage: "folder")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Button {
                    appState.selectedSection = .dropZone
                } label: {
                    Label("Go to Drop Zone", systemImage: "arrow.down.doc")
                }
                .controlSize(.large)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

// MARK: - Archive Info Sheet
public struct ArchiveInfoSheet: View {
    @Environment(\.dismiss) private var dismiss
    public let metadata: ArchiveMetadata

    public var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 12) {
                Image(systemName: metadata.format?.iconName ?? "archivebox.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(.tint)
                VStack(alignment: .leading, spacing: 4) {
                    Text(metadata.archiveURL.lastPathComponent)
                        .font(.headline)
                    Text(metadata.formatName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Divider()

            Grid(alignment: .leading, horizontalSpacing: 24, verticalSpacing: 10) {
                GridRow {
                    Text("Physical File Size:").bold()
                    Text(metadata.humanReadablePhysicalSize)
                }
                GridRow {
                    Text("Uncompressed Size:").bold()
                    Text(metadata.humanReadableUncompressedSize)
                }
                GridRow {
                    Text("Overall Ratio:").bold()
                    Text(metadata.overallRatioString)
                }
                GridRow {
                    Text("Total Files:").bold()
                    Text("\(metadata.fileCount) files, \(metadata.folderCount) folders")
                }
                GridRow {
                    Text("Solid Archive:").bold()
                    Text(metadata.isSolid ? "Yes" : "No")
                }
                GridRow {
                    Text("Encrypted:").bold()
                    Text(metadata.isEncrypted ? "Yes (Password Protected)" : "No")
                }
                GridRow {
                    Text("Volumes:").bold()
                    Text("\(metadata.volumesCount)")
                }
                if let comment = metadata.comment, !comment.isEmpty {
                    GridRow {
                        Text("Comment:").bold()
                        Text(comment)
                    }
                }
            }
            .font(.callout)

            Divider()

            HStack {
                Spacer()
                Button("Done") {
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .controlSize(.large)
            }
        }
        .padding(24)
        .frame(minWidth: 420)
    }
}

// Helper extension for double click
extension View {
    func onDoubleClick(perform action: @escaping () -> Void) -> some View {
        self.modifier(DoubleClickHandler(action: action))
    }
}

struct DoubleClickHandler: ViewModifier {
    let action: () -> Void
    func body(content: Content) -> some View {
        content.simultaneousGesture(
            TapGesture(count: 2).onEnded {
                action()
            }
        )
    }
}
