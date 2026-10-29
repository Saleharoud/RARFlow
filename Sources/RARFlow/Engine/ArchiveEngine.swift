import Foundation
import AppKit

public enum ArchiveError: LocalizedError, Sendable {
    case helperNotFound(String)
    case passwordRequired
    case wrongPassword
    case extractionFailed(String)
    case compressionFailed(String)
    case processCancelled
    case fileNotFound(String)
    case corruptedArchive(String)
    case unsupportedOperation(String)

    public var errorDescription: String? {
        switch self {
        case .helperNotFound(let name):
            return "Required helper tool '\(name)' could not be found."
        case .passwordRequired:
            return "This archive is encrypted and requires a password to open or extract."
        case .wrongPassword:
            return "The password entered is incorrect."
        case .extractionFailed(let msg):
            return "Extraction failed: \(msg)"
        case .compressionFailed(let msg):
            return "Compression failed: \(msg)"
        case .processCancelled:
            return "Operation was cancelled by the user."
        case .fileNotFound(let path):
            return "File not found: \(path)"
        case .corruptedArchive(let msg):
            return "Archive appears corrupted or incomplete: \(msg)"
        case .unsupportedOperation(let msg):
            return msg
        }
    }
}

final class OutputBox: @unchecked Sendable {
    private let lock = NSLock()
    private var buffer = ""

    func append(_ text: String) {
        lock.lock()
        defer { lock.unlock() }
        buffer += text
    }

    var value: String {
        lock.lock()
        defer { lock.unlock() }
        return buffer
    }
}

public actor ArchiveEngine {
    public static let shared = ArchiveEngine()
    private var activeProcess: Process?

    public init() {}

    public func cancelActiveOperation() {
        if let proc = activeProcess, proc.isRunning {
            proc.terminate()
        }
        activeProcess = nil
    }

    // MARK: - List Archive Contents
    public func listArchive(url: URL, password: String? = nil) async throws -> (metadata: ArchiveMetadata, items: [ArchiveItem]) {
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw ArchiveError.fileNotFound(url.path)
        }

        guard let sevenZip = HelperLocator.findSevenZip() else {
            // If 7zz is missing, try lsar as fallback
            if let lsar = HelperLocator.findLsar() {
                return try await listWithLsar(lsarURL: lsar, archiveURL: url, password: password)
            }
            throw ArchiveError.helperNotFound("7zz")
        }

        var arguments = ["l", "-slt", "-sccUTF-8", url.path]
        if let pwd = password, !pwd.isEmpty {
            arguments.append("-p\(pwd)")
        } else {
            arguments.append("-p") // Empty password avoids interactive stdin hanging
        }

        let (stdout, stderr, exitCode) = try await runProcess(executable: sevenZip, arguments: arguments)

        if exitCode != 0 {
            let combined = (stdout + "\n" + stderr).lowercased()
            if combined.contains("enter password") ||
               combined.contains("can not open encrypted archive") ||
               combined.contains("wrong password") ||
               combined.contains("encrypted") {
                throw ArchiveError.passwordRequired
            }

            // Fallback to lsar if 7zz had an issue
            if let lsar = HelperLocator.findLsar() {
                return try await listWithLsar(lsarURL: lsar, archiveURL: url, password: password)
            }

            throw ArchiveError.extractionFailed(stderr.isEmpty ? stdout : stderr)
        }

        let parsed = SevenZipParser.parseSLTOutput(output: stdout, archiveURL: url)
        return parsed
    }

    private func listWithLsar(lsarURL: URL, archiveURL: URL, password: String?) async throws -> (metadata: ArchiveMetadata, items: [ArchiveItem]) {
        var arguments = ["-j"]
        if let pwd = password, !pwd.isEmpty {
            arguments.append(contentsOf: ["-p", pwd])
        }
        arguments.append(archiveURL.path)

        let (stdout, stderr, exitCode) = try await runProcess(executable: lsarURL, arguments: arguments)
        if exitCode != 0 {
            let combined = (stdout + "\n" + stderr).lowercased()
            if combined.contains("password") || combined.contains("encrypted") {
                throw ArchiveError.passwordRequired
            }
            throw ArchiveError.extractionFailed(stderr.isEmpty ? stdout : stderr)
        }

        guard let data = stdout.data(using: .utf8) else {
            throw ArchiveError.corruptedArchive("Unable to decode listing output")
        }
        return try LsarParser.parseJSONOutput(data: data, archiveURL: archiveURL)
    }

    // MARK: - Extract Archive
    public func extractArchive(
        url: URL,
        items: [ArchiveItem]? = nil,
        destination: URL,
        settings: ExtractionSettings,
        password: String? = nil,
        progressHandler: @escaping @Sendable (Double, String) -> Void
    ) async throws -> URL {
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw ArchiveError.fileNotFound(url.path)
        }

        if ArchiveFormat.detect(from: url) == .rar, let unrar = HelperLocator.findUnrarExecutable() {
            return try await extractWithUnrar(
                unrarURL: unrar,
                url: url,
                items: items,
                destination: destination,
                settings: settings,
                password: password,
                progressHandler: progressHandler
            )
        }

        guard let sevenZip = HelperLocator.findSevenZip() else {
            throw ArchiveError.helperNotFound("7zz")
        }

        // Determine destination folder
        var finalDest = destination
        if settings.createSubfolder {
            let folderName = url.deletingPathExtension().lastPathComponent
            finalDest = destination.appendingPathComponent(folderName, isDirectory: true)
        }

        try FileManager.default.createDirectory(at: finalDest, withIntermediateDirectories: true)

        var arguments = [
            "x",
            "-y",
            "-sccUTF-8",
            "-bsp1",
            settings.overwritePolicy.sevenZipSwitch,
            "-o\(finalDest.path)",
            url.path
        ]

        if let pwd = password, !pwd.isEmpty {
            arguments.append("-p\(pwd)")
        } else {
            arguments.append("-p")
        }

        if let selectedItems = items, !selectedItems.isEmpty {
            for item in selectedItems {
                arguments.append(item.path)
            }
        }

        let process = Process()
        process.executableURL = sevenZip
        process.arguments = arguments
        self.activeProcess = process

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        let stdoutHandle = stdoutPipe.fileHandleForReading
        let outputAccumulator = OutputBox()

        stdoutHandle.readabilityHandler = { handle in
            let data = handle.availableData
            guard !data.isEmpty, let text = String(data: data, encoding: .utf8) else { return }
            outputAccumulator.append(text)
            if let pct = SevenZipParser.parseProgressPercentage(from: text) {
                // Find file name if available
                let lines = text.components(separatedBy: .newlines)
                let currentItem = lines.first(where: { !$0.contains("%") && !$0.isEmpty }) ?? ""
                progressHandler(pct, currentItem)
            }
        }

        try process.run()
        process.waitUntilExit()
        stdoutHandle.readabilityHandler = nil
        self.activeProcess = nil

        let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
        let stderrText = String(data: stderrData, encoding: .utf8) ?? ""
        let combined = (outputAccumulator.value + "\n" + stderrText).lowercased()

        if process.terminationStatus != 0 {
            if combined.contains("wrong password") ||
               combined.contains("can not open encrypted archive") ||
               combined.contains("enter password") {
                throw ArchiveError.wrongPassword
            }
            throw ArchiveError.extractionFailed(stderrText.isEmpty ? outputAccumulator.value : stderrText)
        }

        progressHandler(1.0, "Completed")

        // Post extraction actions
        if settings.deleteArchiveAfter {
            try? FileManager.default.trashItem(at: url, resultingItemURL: nil)
        }

        return finalDest
    }

    private func extractWithUnrar(
        unrarURL: URL,
        url: URL,
        items: [ArchiveItem]?,
        destination: URL,
        settings: ExtractionSettings,
        password: String?,
        progressHandler: @escaping @Sendable (Double, String) -> Void
    ) async throws -> URL {
        var finalDest = destination
        if settings.createSubfolder {
            let folderName = url.deletingPathExtension().lastPathComponent
            finalDest = destination.appendingPathComponent(folderName, isDirectory: true)
        }
        try FileManager.default.createDirectory(at: finalDest, withIntermediateDirectories: true)

        var arguments = ["x", "-y"]
        if settings.overwritePolicy == .skip {
            arguments.append("-o-")
        } else {
            arguments.append("-o+")
        }

        if let pwd = password, !pwd.isEmpty {
            arguments.append("-p\(pwd)")
        } else {
            arguments.append("-p-")
        }

        arguments.append(url.path)

        if let selectedItems = items, !selectedItems.isEmpty {
            for item in selectedItems {
                arguments.append(item.path)
            }
        }

        var destPath = finalDest.path
        if !destPath.hasSuffix("/") { destPath += "/" }
        arguments.append(destPath)

        let (stdout, stderr, exitCode) = try await runProcess(executable: unrarURL, arguments: arguments)
        let combined = (stdout + "\n" + stderr).lowercased()

        if exitCode != 0 {
            if combined.contains("wrong password") ||
               combined.contains("password") ||
               combined.contains("encrypted") {
                throw ArchiveError.wrongPassword
            }
            throw ArchiveError.extractionFailed(stderr.isEmpty ? stdout : stderr)
        }

        progressHandler(1.0, "Extraction Complete")

        if settings.deleteArchiveAfter {
            try? FileManager.default.trashItem(at: url, resultingItemURL: nil)
        }

        return finalDest
    }

    // MARK: - Compress Files
    public func compressFiles(
        sources: [URL],
        destination: URL,
        settings: CompressionSettings,
        progressHandler: @escaping @Sendable (Double, String) -> Void
    ) async throws {
        guard !sources.isEmpty else {
            throw ArchiveError.fileNotFound("No source files provided for compression")
        }

        guard let sevenZip = HelperLocator.findSevenZip() else {
            throw ArchiveError.helperNotFound("7zz")
        }

        // Ensure parent directory exists
        let parentDir = destination.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: parentDir, withIntermediateDirectories: true)

        var arguments = [
            "a",
            "-y",
            "-sccUTF-8",
            "-bsp1",
            "-mx\(settings.level.rawValue)",
            "-mmt=\(settings.threadCount)"
        ]

        // Archive format switch
        switch settings.format {
        case .sevenZip:
            arguments.append("-t7z")
            arguments.append("-m0=\(settings.method.switchValue)")
            arguments.append("-ms=\(settings.isSolid ? "on" : "off")")
            if !settings.password.isEmpty && settings.encryptHeader {
                arguments.append("-mhe=on")
            }
        case .zip:
            arguments.append("-tzip")
            if settings.method == .deflate || settings.method == .deflate64 {
                arguments.append("-mm=\(settings.method.switchValue)")
            }
        case .tar:
            arguments.append("-ttar")
        case .gzip:
            arguments.append("-tgzip")
        case .bzip2:
            arguments.append("-tbzip2")
        case .xz:
            arguments.append("-txz")
        case .rar:
            if let rarExe = HelperLocator.findRarExecutable() {
                return try await compressWithRar(
                    rarExecutable: rarExe,
                    sources: sources,
                    destination: destination,
                    settings: settings,
                    progressHandler: progressHandler
                )
            } else {
                throw ArchiveError.unsupportedOperation("Direct RAR creation requires RARLAB's 'rar' binary. Please select 7Z, ZIP, or TAR formats or configure the rar tool path in Settings.")
            }
        }

        // Password protection
        if !settings.password.isEmpty {
            arguments.append("-p\(settings.password)")
        }

        // Volume splitting
        if let splitArg = settings.splitArgument {
            arguments.append("-v\(splitArg)")
        }

        // Strip macOS metadata files
        if settings.excludeMacMetadata {
            arguments.append("-xr!.DS_Store")
            arguments.append("-xr!__MACOSX")
            arguments.append("-xr!.Trashes")
            arguments.append("-xr!.Spotlight-V100")
            arguments.append("-xr!._*")
        }

        // Delete source files if requested
        if settings.deleteSourceAfter {
            arguments.append("-sdel")
        }

        // Destination archive path
        arguments.append(destination.path)

        // Sources
        for src in sources {
            arguments.append(src.path)
        }

        let process = Process()
        process.executableURL = sevenZip
        process.arguments = arguments
        self.activeProcess = process

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        let stdoutHandle = stdoutPipe.fileHandleForReading
        let outputAccumulator = OutputBox()

        stdoutHandle.readabilityHandler = { handle in
            let data = handle.availableData
            guard !data.isEmpty, let text = String(data: data, encoding: .utf8) else { return }
            outputAccumulator.append(text)
            if let pct = SevenZipParser.parseProgressPercentage(from: text) {
                progressHandler(pct, "Compressing...")
            }
        }

        try process.run()
        process.waitUntilExit()
        stdoutHandle.readabilityHandler = nil
        self.activeProcess = nil

        let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
        let stderrText = String(data: stderrData, encoding: .utf8) ?? ""

        if process.terminationStatus != 0 {
            throw ArchiveError.compressionFailed(stderrText.isEmpty ? outputAccumulator.value : stderrText)
        }

        progressHandler(1.0, "Compression Complete")
    }

    private func compressWithRar(
        rarExecutable: URL,
        sources: [URL],
        destination: URL,
        settings: CompressionSettings,
        progressHandler: @escaping @Sendable (Double, String) -> Void
    ) async throws {
        var arguments = ["a", "-y", "-ep1"]

        let rarLevel: Int
        switch settings.level {
        case .store: rarLevel = 0
        case .fastest: rarLevel = 1
        case .fast: rarLevel = 2
        case .normal: rarLevel = 3
        case .maximum: rarLevel = 4
        case .ultra: rarLevel = 5
        }
        arguments.append("-m\(rarLevel)")

        if !settings.password.isEmpty {
            if settings.encryptHeader {
                arguments.append("-hp\(settings.password)")
            } else {
                arguments.append("-p\(settings.password)")
            }
        }

        if let splitArg = settings.splitArgument {
            arguments.append("-v\(splitArg)")
        }

        if settings.isSolid {
            arguments.append("-s")
        }

        if settings.excludeMacMetadata {
            arguments.append("-x*.DS_Store")
            arguments.append("-x*__MACOSX*")
            arguments.append("-x*.Trashes*")
            arguments.append("-x*.Spotlight-V100*")
            arguments.append("-x*._*")
        }

        if settings.deleteSourceAfter {
            arguments.append("-df")
        }

        arguments.append(destination.path)
        for src in sources {
            arguments.append(src.path)
        }

        let process = Process()
        process.executableURL = rarExecutable
        process.arguments = arguments
        self.activeProcess = process

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        let stdoutHandle = stdoutPipe.fileHandleForReading
        let outputAccumulator = OutputBox()

        stdoutHandle.readabilityHandler = { handle in
            let data = handle.availableData
            guard !data.isEmpty, let text = String(data: data, encoding: .utf8) else { return }
            outputAccumulator.append(text)
            if let pct = SevenZipParser.parseProgressPercentage(from: text) {
                progressHandler(pct, "Compressing RAR...")
            }
        }

        try process.run()
        process.waitUntilExit()
        stdoutHandle.readabilityHandler = nil
        self.activeProcess = nil

        let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
        let stderrText = String(data: stderrData, encoding: .utf8) ?? ""

        if process.terminationStatus != 0 {
            throw ArchiveError.compressionFailed(stderrText.isEmpty ? outputAccumulator.value : stderrText)
        }

        progressHandler(1.0, "RAR Compression Complete")
    }

    // MARK: - Test Archive Integrity
    public func testArchiveIntegrity(url: URL, password: String? = nil) async throws -> Bool {
        guard let sevenZip = HelperLocator.findSevenZip() else {
            throw ArchiveError.helperNotFound("7zz")
        }

        var arguments = ["t", "-y", "-sccUTF-8", url.path]
        if let pwd = password, !pwd.isEmpty {
            arguments.append("-p\(pwd)")
        } else {
            arguments.append("-p")
        }

        let (stdout, stderr, exitCode) = try await runProcess(executable: sevenZip, arguments: arguments)
        let combined = stdout + "\n" + stderr
        if exitCode == 0 && combined.contains("Everything is Ok") {
            return true
        }
        return false
    }

    // MARK: - Extract Single Item for Quick Look
    public func extractSingleItemForPreview(archiveURL: URL, item: ArchiveItem, password: String? = nil) async throws -> URL {
        guard let sevenZip = HelperLocator.findSevenZip() else {
            throw ArchiveError.helperNotFound("7zz")
        }

        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("RARFlow_preview_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

        var arguments = [
            "e", // Flat extract
            "-y",
            "-sccUTF-8",
            "-o\(tempDir.path)",
            archiveURL.path,
            item.path
        ]

        if let pwd = password, !pwd.isEmpty {
            arguments.append("-p\(pwd)")
        } else {
            arguments.append("-p")
        }

        let (_, stderr, exitCode) = try await runProcess(executable: sevenZip, arguments: arguments)
        if exitCode != 0 {
            throw ArchiveError.extractionFailed("Failed to extract preview item: \(stderr)")
        }

        let extractedURL = tempDir.appendingPathComponent(item.filename)
        return extractedURL
    }

    // MARK: - Process Helper
    private func runProcess(executable: URL, arguments: [String]) async throws -> (stdout: String, stderr: String, exitCode: Int32) {
        let process = Process()
        process.executableURL = executable
        process.arguments = arguments

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        try process.run()

        let stdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
        let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()

        process.waitUntilExit()

        let stdout = String(data: stdoutData, encoding: .utf8) ?? ""
        let stderr = String(data: stderrData, encoding: .utf8) ?? ""

        return (stdout, stderr, process.terminationStatus)
    }
}
