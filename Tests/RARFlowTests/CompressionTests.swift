import Testing
import Foundation
@testable import RARFlow

struct CompressionTests {
    @Test func testLiveCompressionAndExtraction() async throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("macRAR_test_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }

        // 1. Create test source files
        let sourceDir = tempDir.appendingPathComponent("sourceFiles")
        try FileManager.default.createDirectory(at: sourceDir, withIntermediateDirectories: true)

        let file1 = sourceDir.appendingPathComponent("sample1.txt")
        let file2 = sourceDir.appendingPathComponent("sample2.txt")
        let content1 = "macRAR test file content 1 - Swift and 7-Zip native integration on macOS."
        let content2 = "macRAR test file content 2 - Compression software specifications testing."
        try content1.write(to: file1, atomically: true, encoding: .utf8)
        try content2.write(to: file2, atomically: true, encoding: .utf8)

        // 2. Compress into 7z archive
        let archive7z = tempDir.appendingPathComponent("test_archive.7z")
        let settings7z = CompressionSettings(
            format: .sevenZip,
            level: .ultra,
            method: .lzma2,
            isSolid: true
        )

        try await ArchiveEngine.shared.compressFiles(
            sources: [file1, file2],
            destination: archive7z,
            settings: settings7z
        ) { _, _ in }

        #expect(FileManager.default.fileExists(atPath: archive7z.path))

        // 3. Test integrity
        let integrity = try await ArchiveEngine.shared.testArchiveIntegrity(url: archive7z)
        #expect(integrity == true)

        // 4. List archive
        let (_, items) = try await ArchiveEngine.shared.listArchive(url: archive7z)
        #expect(items.count == 2)
        #expect(items.contains(where: { $0.filename == "sample1.txt" }))
        #expect(items.contains(where: { $0.filename == "sample2.txt" }))

        // 5. Extract archive
        let extractDir = tempDir.appendingPathComponent("extracted")
        let extractSettings = ExtractionSettings(
            createSubfolder: false,
            revealInFinder: false,
            playSound: false
        )

        let finalDest = try await ArchiveEngine.shared.extractArchive(
            url: archive7z,
            destination: extractDir,
            settings: extractSettings
        ) { _, _ in }

        let extracted1 = finalDest.appendingPathComponent("sample1.txt")
        let extracted2 = finalDest.appendingPathComponent("sample2.txt")
        #expect(FileManager.default.fileExists(atPath: extracted1.path))
        #expect(FileManager.default.fileExists(atPath: extracted2.path))

        let readContent1 = try String(contentsOf: extracted1, encoding: .utf8)
        #expect(readContent1 == content1)
    }

    @Test func testEncryptedArchiveCreationAndExtraction() async throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("macRAR_enc_test_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }

        let secretFile = tempDir.appendingPathComponent("confidential.txt")
        let secretData = "Top secret password protected content inside macRAR."
        try secretData.write(to: secretFile, atomically: true, encoding: .utf8)

        let encArchive = tempDir.appendingPathComponent("secret.7z")
        let encSettings = CompressionSettings(
            format: .sevenZip,
            level: .normal,
            password: "SecretPassword123!",
            encryptHeader: true
        )

        try await ArchiveEngine.shared.compressFiles(
            sources: [secretFile],
            destination: encArchive,
            settings: encSettings
        ) { _, _ in }

        #expect(FileManager.default.fileExists(atPath: encArchive.path))

        // Opening without password on an archive with encrypted header should throw passwordRequired
        await #expect(throws: ArchiveError.self) {
            _ = try await ArchiveEngine.shared.listArchive(url: encArchive, password: nil)
        }

        // Opening with correct password succeeds
        let (_, items) = try await ArchiveEngine.shared.listArchive(url: encArchive, password: "SecretPassword123!")
        #expect(items.count == 1)
        #expect(items.first?.filename == "confidential.txt")

        // Extracting with correct password
        let dest = tempDir.appendingPathComponent("decrypted")
        let extractSettings = ExtractionSettings(
            createSubfolder: false,
            revealInFinder: false,
            playSound: false
        )

        let finalDest = try await ArchiveEngine.shared.extractArchive(
            url: encArchive,
            destination: dest,
            settings: extractSettings,
            password: "SecretPassword123!"
        ) { _, _ in }

        let extractedFile = finalDest.appendingPathComponent("confidential.txt")
        #expect(FileManager.default.fileExists(atPath: extractedFile.path))
        let extractedContent = try String(contentsOf: extractedFile, encoding: .utf8)
        #expect(extractedContent == secretData)
    }

    @Test func testZipCompression() async throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("macRAR_zip_test_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }

        let sample = tempDir.appendingPathComponent("hello.txt")
        try "Hello from macRAR ZIP test".write(to: sample, atomically: true, encoding: .utf8)

        let zipArchive = tempDir.appendingPathComponent("hello.zip")
        let zipSettings = CompressionSettings(
            format: .zip,
            level: .normal,
            method: .deflate
        )

        try await ArchiveEngine.shared.compressFiles(
            sources: [sample],
            destination: zipArchive,
            settings: zipSettings
        ) { _, _ in }

        #expect(FileManager.default.fileExists(atPath: zipArchive.path))
        let (_, items) = try await ArchiveEngine.shared.listArchive(url: zipArchive)
        #expect(items.count == 1)
        #expect(items.first?.filename == "hello.txt")
    }

    @Test func testRarCreationAndExtraction() async throws {
        guard HelperLocator.findRarExecutable() != nil else {
            return // Skip if rar CLI not available
        }

        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("macRAR_rar_test_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }

        let sample = tempDir.appendingPathComponent("rar_test.txt")
        let content = "Testing native RAR creation and extraction inside macRAR on Apple Silicon macOS!"
        try content.write(to: sample, atomically: true, encoding: .utf8)

        let rarArchive = tempDir.appendingPathComponent("rar_test.rar")
        let rarSettings = CompressionSettings(
            format: .rar,
            level: .normal
        )

        try await ArchiveEngine.shared.compressFiles(
            sources: [sample],
            destination: rarArchive,
            settings: rarSettings
        ) { _, _ in }

        #expect(FileManager.default.fileExists(atPath: rarArchive.path))

        // List the RAR archive
        let (meta, items) = try await ArchiveEngine.shared.listArchive(url: rarArchive)
        #expect(items.count == 1)
        #expect(items.first?.filename == "rar_test.txt")
        #expect(meta.formatName.lowercased().contains("rar"))

        // Extract the RAR archive
        let extractDir = tempDir.appendingPathComponent("rar_extracted")
        let extractSettings = ExtractionSettings(
            createSubfolder: false,
            revealInFinder: false,
            playSound: false
        )

        let finalDest = try await ArchiveEngine.shared.extractArchive(
            url: rarArchive,
            destination: extractDir,
            settings: extractSettings
        ) { _, _ in }

        let extractedFile = finalDest.appendingPathComponent("rar_test.txt")
        #expect(FileManager.default.fileExists(atPath: extractedFile.path))
        let extractedContent = try String(contentsOf: extractedFile, encoding: .utf8)
        #expect(extractedContent == content)
    }
}
