import SwiftUI
import AppKit

public struct CompressDialogView: View {
    @Bindable var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var archiveName: String = ""
    @State private var destinationFolder: URL = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first!
    @State private var format: ArchiveFormat = .sevenZip
    @State private var level: CompressionLevel = .normal
    @State private var method: CompressionMethod = .lzma2
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var showPasswordPlain: Bool = false
    @State private var encryptHeader: Bool = false
    @State private var splitPreset: SplitVolumePreset = .none
    @State private var customSplitMB: Int = 100
    @State private var excludeMacMetadata: Bool = true
    @State private var isSolid: Bool = true
    @State private var deleteSourceAfter: Bool = false
    @State private var threadCount: Int = ProcessInfo.processInfo.activeProcessorCount
    @State private var validationError: String?

    public var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 12) {
                Image(systemName: "archivebox.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(.tint)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Create Archive")
                        .font(.title3.bold())
                    Text("Compressing \(appState.compressSourceURLs.count) item(s) • Total raw size: \(totalSourceSizeString)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 12)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Output destination & name
                    outputSection

                    Divider()

                    // Format & Level
                    formatAndLevelSection

                    Divider()

                    // Encryption & Password
                    encryptionSection

                    Divider()

                    // Splitting & Advanced
                    advancedSection
                }
                .padding(24)
            }

            if let err = validationError {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                    Text(err)
                        .font(.caption.bold())
                        .foregroundStyle(.red)
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 6)
                .background(Color.red.opacity(0.1))
            }

            Divider()

            // Action Buttons
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button("Compress") {
                    validateAndStart()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                .controlSize(.large)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(RARFlowTheme.bgToolbar)
        }
        .frame(width: 580, height: 640)
        .background(RARFlowTheme.bgWindow)
        .onAppear {
            initializeDefaults()
        }
    }

    // MARK: - Sections
    private var outputSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("OUTPUT ARCHIVE")
                .font(.caption2.bold())
                .foregroundStyle(.secondary)
                .tracking(1.0)

            HStack(spacing: 10) {
                Text("Archive Name:")
                    .frame(width: 110, alignment: .leading)
                TextField("Archive Name", text: $archiveName)
                    .textFieldStyle(.roundedBorder)
                Text(".\(format.fileExtension)")
                    .foregroundStyle(.secondary)
                    .font(.callout.monospaced())
            }

            HStack(spacing: 10) {
                Text("Save To:")
                    .frame(width: 110, alignment: .leading)
                Text(destinationFolder.path)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(Color(nsColor: .controlBackgroundColor))
                    .cornerRadius(6)

                Button("Browse...") {
                    let panel = NSOpenPanel()
                    panel.canChooseFiles = false
                    panel.canChooseDirectories = true
                    panel.canCreateDirectories = true
                    panel.prompt = "Choose"
                    if panel.runModal() == .OK, let url = panel.url {
                        destinationFolder = url
                    }
                }
            }
        }
    }

    private var formatAndLevelSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("COMPRESSION SETTINGS")
                .font(.caption2.bold())
                .foregroundStyle(.secondary)
                .tracking(1.0)

            HStack(spacing: 10) {
                Text("Archive Format:")
                    .frame(width: 110, alignment: .leading)
                Picker("", selection: $format) {
                    ForEach(ArchiveFormat.creationFormats) { fmt in
                        Text(fmt.displayName).tag(fmt)
                    }
                }
                .labelsHidden()
            }

            HStack(spacing: 10) {
                Text("Compression:")
                    .frame(width: 110, alignment: .leading)
                Picker("", selection: $level) {
                    ForEach(CompressionLevel.allCases) { lvl in
                        Text(lvl.title).tag(lvl)
                    }
                }
                .labelsHidden()
            }

            if format == .sevenZip || format == .zip {
                HStack(spacing: 10) {
                    Text("Method:")
                        .frame(width: 110, alignment: .leading)
                    Picker("", selection: $method) {
                        ForEach(CompressionMethod.allCases) { m in
                            Text(m.rawValue).tag(m)
                        }
                    }
                    .labelsHidden()
                }
            }
        }
    }

    private var encryptionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("SECURITY & ENCRYPTION")
                .font(.caption2.bold())
                .foregroundStyle(.secondary)
                .tracking(1.0)

            HStack(spacing: 10) {
                Text("Password:")
                    .frame(width: 110, alignment: .leading)
                if showPasswordPlain {
                    TextField("Optional password", text: $password)
                        .textFieldStyle(.roundedBorder)
                } else {
                    SecureField("Optional password", text: $password)
                        .textFieldStyle(.roundedBorder)
                }

                Button {
                    showPasswordPlain.toggle()
                } label: {
                    Image(systemName: showPasswordPlain ? "eye.slash" : "eye")
                }
                .buttonStyle(.borderless)
            }

            if !password.isEmpty {
                HStack(spacing: 10) {
                    Text("Confirm:")
                        .frame(width: 110, alignment: .leading)
                    if showPasswordPlain {
                        TextField("Confirm password", text: $confirmPassword)
                            .textFieldStyle(.roundedBorder)
                    } else {
                        SecureField("Confirm password", text: $confirmPassword)
                            .textFieldStyle(.roundedBorder)
                    }
                }

                if format == .sevenZip {
                    Toggle("Encrypt file names (Hide archive contents without password)", isOn: $encryptHeader)
                        .padding(.leading, 120)
                }
            }
        }
    }

    private var advancedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("ADVANCED & MAC OPTIMIZATIONS")
                .font(.caption2.bold())
                .foregroundStyle(.secondary)
                .tracking(1.0)

            HStack(spacing: 10) {
                Text("Split Volume:")
                    .frame(width: 110, alignment: .leading)
                Picker("", selection: $splitPreset) {
                    ForEach(SplitVolumePreset.allCases) { preset in
                        Text(preset.rawValue).tag(preset)
                    }
                }
                .labelsHidden()

                if splitPreset == .custom {
                    TextField("MB", value: $customSplitMB, format: .number)
                        .frame(width: 70)
                        .textFieldStyle(.roundedBorder)
                    Text("MB per volume")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Toggle("Strip macOS metadata files (.DS_Store, __MACOSX, .Trashes)", isOn: $excludeMacMetadata)
                Text("Recommended: prevents unwanted Mac system files when sending to Windows or Linux users.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.leading, 20)

                if format == .sevenZip {
                    Toggle("Solid archive (higher compression ratio for multiple similar files)", isOn: $isSolid)
                }

                Toggle("Delete source files after successful compression", isOn: $deleteSourceAfter)
            }
            .padding(.top, 4)
        }
    }

    // MARK: - Helpers
    private var totalSourceSizeString: String {
        var total: Int64 = 0
        for url in appState.compressSourceURLs {
            if let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
               let size = attrs[.size] as? NSNumber {
                total += size.int64Value
            }
        }
        return ByteCountFormatter.string(fromByteCount: total, countStyle: .file)
    }

    private func initializeDefaults() {
        if let first = appState.compressSourceURLs.first {
            archiveName = first.deletingPathExtension().lastPathComponent
            if appState.compressSourceURLs.count == 1 && first.hasDirectoryPath {
                destinationFolder = first.deletingLastPathComponent()
            }
        } else {
            archiveName = "Archive"
        }
    }

    private func validateAndStart() {
        validationError = nil

        let trimmedName = archiveName.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else {
            validationError = "Please enter an archive name."
            return
        }

        if !password.isEmpty && password != confirmPassword {
            validationError = "Passwords do not match."
            return
        }

        let fullFileName = "\(trimmedName).\(format.fileExtension)"
        let finalDestinationURL = destinationFolder.appendingPathComponent(fullFileName)

        let settings = CompressionSettings(
            format: format,
            level: level,
            method: method,
            password: password,
            encryptHeader: encryptHeader,
            splitPreset: splitPreset,
            customSplitMB: customSplitMB,
            excludeMacMetadata: excludeMacMetadata,
            isSolid: isSolid,
            threadCount: threadCount,
            deleteSourceAfter: deleteSourceAfter
        )

        dismiss()
        appState.executeCompression(destination: finalDestinationURL, settings: settings)
    }
}
