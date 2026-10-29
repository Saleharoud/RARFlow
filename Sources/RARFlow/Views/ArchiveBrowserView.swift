import SwiftUI
import AppKit

public struct ArchiveBrowserView: View {
    @Bindable var appState: AppState
    @State private var sortOrder = [KeyPathComparator(\ArchiveItem.filename)]

    public var body: some View {
        VStack(spacing: 0) {
            if let activeURL = appState.activeArchiveURL {
                // Optional subfolder navigation bar
                if !appState.currentFolderPrefix.isEmpty || appState.isFlatView {
                    folderNavigationBar(activeURL: activeURL)
                    Divider()
                        .background(RARFlowTheme.borderSubtle)
                }

                // File Table
                if appState.displayedItems.isEmpty {
                    emptyFolderView
                } else {
                    fileTable
                }

                Divider()
                    .background(RARFlowTheme.borderSubtle)

                // Bottom Status Bar
                bottomStatusBar
            } else {
                noArchivePlaceholder
            }
        }
        .background(RARFlowTheme.bgWindow)
        .sheet(isPresented: $appState.showInfoSheet) {
            if let meta = appState.archiveMetadata {
                ArchiveInfoSheet(metadata: meta)
            }
        }
    }

    // MARK: - Subfolder Navigation Bar
    private func folderNavigationBar(activeURL: URL) -> some View {
        HStack(spacing: 10) {
            if !appState.currentFolderPrefix.isEmpty {
                Button {
                    navigateUp()
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 11, weight: .semibold))
                        Text("Up")
                            .font(.system(size: 12, weight: .medium))
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
                .buttonStyle(.plain)

                HStack(spacing: 4) {
                    Image(systemName: "folder.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(RARFlowTheme.accentCyan)
                    Text(appState.currentFolderPrefix)
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundStyle(RARFlowTheme.textSecondary)
                }
            } else {
                Text(activeURL.lastPathComponent)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(RARFlowTheme.textSecondary)
            }

            Spacer()

            // Flat View Toggle
            Button {
                appState.isFlatView.toggle()
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: appState.isFlatView ? "list.bullet.rectangle" : "folder")
                        .font(.system(size: 11))
                    Text(appState.isFlatView ? "Flat View" : "Folders")
                        .font(.system(size: 11, weight: .medium))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(appState.isFlatView ? RARFlowTheme.bgPillActive : RARFlowTheme.bgPill)
                .overlay(
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(RARFlowTheme.borderSubtle, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 5))
            }
            .buttonStyle(.plain)
            .help("Toggle between hierarchical folder view and flat list of all files")

            // Info Button
            Button {
                appState.showInfoSheet = true
            } label: {
                Image(systemName: "info.circle")
                    .font(.system(size: 12))
                    .foregroundStyle(RARFlowTheme.textSecondary)
                    .padding(5)
                    .background(RARFlowTheme.bgPill)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .help("View archive technical details")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .background(RARFlowTheme.bgTableHeader)
    }

    // MARK: - File Table
    private var fileTable: some View {
        Table(appState.displayedItems, selection: $appState.selectedItemIDs, sortOrder: $sortOrder) {
            TableColumn("Name") { item in
                HStack(spacing: 8) {
                    Image(systemName: item.systemIconName)
                        .font(.system(size: 13))
                        .foregroundStyle(item.iconColor)
                        .frame(width: 18)

                    Text(item.filename)
                        .font(.system(size: 13, weight: item.isDirectory ? .medium : .regular))
                        .foregroundStyle(RARFlowTheme.textPrimary)
                        .lineLimit(1)

                    if item.isEncrypted {
                        Text("AES-256")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(RARFlowTheme.accentAmber)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                }
                .contextMenu {
                    tableItemContextMenu(item: item)
                }
            }
            .width(min: 220, ideal: 320)

            TableColumn("Size") { item in
                Text(item.humanReadableSize)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(RARFlowTheme.textSecondary)
            }
            .width(min: 75, ideal: 95)

            TableColumn("Packed") { item in
                Text(item.humanReadableCompressedSize)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(RARFlowTheme.textSecondary)
            }
            .width(min: 75, ideal: 95)

            TableColumn("Ratio") { item in
                if let ratio = item.ratioDouble {
                    Text(String(format: "%.1f%%", ratio))
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                        .foregroundStyle(ratio < 50.0 ? RARFlowTheme.accentCyan : RARFlowTheme.accentGreen)
                } else {
                    Text("--")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(RARFlowTheme.textMuted)
                }
            }
            .width(min: 65, ideal: 75)

            TableColumn("Modified") { item in
                Text(item.formattedDate)
                    .font(.system(size: 12))
                    .foregroundStyle(RARFlowTheme.textSecondary)
            }
            .width(min: 120, ideal: 140)

            TableColumn("CRC32") { item in
                Text(item.crc32 ?? "--")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(RARFlowTheme.textMuted)
            }
            .width(min: 75, ideal: 90)
        }
        .alternatingRowBackgrounds(.disabled)
        .scrollContentBackground(.hidden)
        .background(RARFlowTheme.bgTable)
        .simultaneousGesture(
            TapGesture(count: 2).onEnded {
                handleDoubleClick()
            }
        )
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
        HStack(spacing: 8) {
            Text("Showing \(appState.displayedItems.count) of \(appState.archiveItems.count) items")
                .foregroundStyle(RARFlowTheme.textMuted)

            if let meta = appState.archiveMetadata {
                Text("•")
                    .foregroundStyle(RARFlowTheme.borderMedium)
                Text("Total Uncompressed: \(meta.humanReadableUncompressedSize)")
                    .foregroundStyle(RARFlowTheme.textMuted)
                Text("•")
                    .foregroundStyle(RARFlowTheme.borderMedium)
                Text("Compressed: \(meta.humanReadablePhysicalSize)")
                    .foregroundStyle(RARFlowTheme.textMuted)
            }

            Spacer()

            if !appState.selectedItemIDs.isEmpty {
                Text("\(appState.selectedItemIDs.count) items selected (\(appState.selectedItemsByteCountString)) — Press ")
                    .foregroundStyle(RARFlowTheme.accentCyan)
                +
                Text("Space")
                    .bold()
                    .foregroundStyle(RARFlowTheme.accentCyan)
                +
                Text(" for Quick Look")
                    .foregroundStyle(RARFlowTheme.accentCyan)
            } else {
                Text("Press Space for Quick Look • Double-click to open")
                    .foregroundStyle(RARFlowTheme.textMuted)
            }
        }
        .font(.system(size: 11))
        .padding(.horizontal, 14)
        .frame(height: 28)
        .background(RARFlowTheme.bgStatusBar)
    }

    // MARK: - Empty States
    private var emptyFolderView: some View {
        VStack(spacing: 12) {
            Image(systemName: "folder.badge.questionmark")
                .font(.system(size: 40))
                .foregroundStyle(RARFlowTheme.textMuted)
            Text(appState.searchQuery.isEmpty ? "This folder is empty" : "No matches found for '\(appState.searchQuery)'")
                .font(.headline)
                .foregroundStyle(RARFlowTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var noArchivePlaceholder: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(RARFlowTheme.accentCyan.opacity(0.10))
                    .frame(width: 100, height: 100)
                Image(systemName: "archivebox")
                    .font(.system(size: 48))
                    .foregroundStyle(RARFlowTheme.accentCyan)
            }

            VStack(spacing: 8) {
                Text("No Archive Loaded")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(RARFlowTheme.textPrimary)

                Text("Open a RAR, 7Z, ZIP, or TAR archive to browse its contents,\nor drag files to the Drop Zone to compress them.")
                    .font(.system(size: 13))
                    .foregroundStyle(RARFlowTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 420)
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
                    appState.selectedSection = .dropZone
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "tray.and.arrow.down.fill")
                        Text("Go to Drop Zone")
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(RARFlowTheme.accentBlue)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Archive Info Sheet
public struct ArchiveInfoSheet: View {
    let metadata: ArchiveMetadata
    @Environment(\.dismiss) private var dismiss

    public var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text("Archive Technical Details")
                    .font(.headline)
                    .foregroundStyle(RARFlowTheme.textPrimary)
                Spacer()
                Button("Done") {
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }

            VStack(spacing: 10) {
                infoRow("Archive File", value: metadata.archiveURL.lastPathComponent)
                infoRow("Format", value: metadata.formatName)
                infoRow("Total Items", value: "\(metadata.fileCount) files, \(metadata.folderCount) folders")
                infoRow("Compressed Size", value: metadata.humanReadablePhysicalSize)
                infoRow("Uncompressed Size", value: metadata.humanReadableUncompressedSize)
                infoRow("Compression Ratio", value: metadata.overallRatioString)
                infoRow("Solid Archive", value: metadata.isSolid ? "Yes (Block compression)" : "No")
                infoRow("Encrypted", value: metadata.isEncrypted ? "Yes (Password protected)" : "No")
                infoRow("Split Volumes", value: metadata.volumesCount > 1 ? "\(metadata.volumesCount) parts" : "Single archive")
            }
            .padding(14)
            .background(RARFlowTheme.bgPill)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            Spacer()
        }
        .padding(20)
        .frame(width: 480, height: 420)
        .background(RARFlowTheme.bgWindow)
    }

    private func infoRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.caption.bold())
                .foregroundStyle(RARFlowTheme.textMuted)
                .frame(width: 140, alignment: .leading)
            Text(value)
                .font(.caption)
                .foregroundStyle(RARFlowTheme.textPrimary)
            Spacer()
        }
    }
}
