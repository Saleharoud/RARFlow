import Testing
import Foundation
@testable import RARFlow

struct EngineTests {
    @Test func testFormatDetection() {
        #expect(ArchiveFormat.detect(from: URL(fileURLWithPath: "/path/to/archive.rar")) == .rar)
        #expect(ArchiveFormat.detect(from: URL(fileURLWithPath: "/path/to/archive.r00")) == .rar)
        #expect(ArchiveFormat.detect(from: URL(fileURLWithPath: "/path/to/archive.cbr")) == .rar)
        #expect(ArchiveFormat.detect(from: URL(fileURLWithPath: "/path/to/archive.7z")) == .sevenZip)
        #expect(ArchiveFormat.detect(from: URL(fileURLWithPath: "/path/to/archive.zip")) == .zip)
        #expect(ArchiveFormat.detect(from: URL(fileURLWithPath: "/path/to/archive.tar")) == .tar)
        #expect(ArchiveFormat.detect(from: URL(fileURLWithPath: "/path/to/archive.tar.gz")) == .gzip)
        #expect(ArchiveFormat.detect(from: URL(fileURLWithPath: "/path/to/archive.tgz")) == .gzip)
        #expect(ArchiveFormat.detect(from: URL(fileURLWithPath: "/path/to/archive.tar.bz2")) == .bzip2)
        #expect(ArchiveFormat.detect(from: URL(fileURLWithPath: "/path/to/archive.tar.xz")) == .xz)
    }

    @Test func testParserSLTOutput() {
        let sampleOutput = """
        7-Zip (z) 26.05 : Copyright (c) 1999-2026 Igor Pavlov : 2026-10-21

        Listing archive: /tmp/test.7z

        --
        Path = /tmp/test.7z
        Type = 7z
        Physical Size = 450
        Headers Size = 180
        Method = LZMA2:12
        Solid = +
        Blocks = 1

        ----------
        Path = folder
        Folder = +
        Size = 0
        Packed Size = 0
        Modified = 2026-10-29 12:00:00
        Attributes = D----
        CRC = 
        Encrypted = -
        Method = 

        ----------
        Path = folder/document.pdf
        Folder = -
        Size = 1048576
        Packed Size = 524288
        Modified = 2026-10-29 12:05:00
        Attributes = A----
        CRC = A1B2C3D4
        Encrypted = -
        Method = LZMA2:24

        ----------
        Path = folder/secret.key
        Folder = -
        Size = 256
        Packed Size = 128
        Modified = 2026-10-29 12:10:00
        Attributes = A----
        CRC = E5F6A7B8
        Encrypted = +
        Method = 7zAES
        """

        let url = URL(fileURLWithPath: "/tmp/test.7z")
        let (metadata, items) = SevenZipParser.parseSLTOutput(output: sampleOutput, archiveURL: url)

        #expect(metadata.formatName == "7z")
        #expect(metadata.totalPhysicalSize == 450)
        #expect(metadata.isSolid == true)
        #expect(metadata.isEncrypted == true)
        #expect(items.count == 3)

        // Folder item
        #expect(items[0].isDirectory == true)
        #expect(items[0].filename == "folder")
        #expect(items[0].humanReadableSize == "--")

        // PDF document
        #expect(items[1].isDirectory == false)
        #expect(items[1].filename == "document.pdf")
        #expect(items[1].uncompressedSize == 1048576)
        #expect(items[1].compressedSize == 524288)
        #expect(items[1].compressionRatioString == "50.0%")
        #expect(items[1].crc32 == "A1B2C3D4")
        #expect(items[1].isEncrypted == false)

        // Encrypted secret key
        #expect(items[2].filename == "secret.key")
        #expect(items[2].isEncrypted == true)
    }

    @Test func testProgressPercentageParser() {
        #expect(SevenZipParser.parseProgressPercentage(from: "  0%") == 0.0)
        #expect(SevenZipParser.parseProgressPercentage(from: " 45%") == 0.45)
        #expect(SevenZipParser.parseProgressPercentage(from: "100%") == 1.0)
        #expect(SevenZipParser.parseProgressPercentage(from: " 65% 12/20") == 0.65)
        #expect(SevenZipParser.parseProgressPercentage(from: "No percent here") == nil)
    }

    @Test func testCompressionSettings() {
        var settings = CompressionSettings()
        #expect(settings.format == .sevenZip)
        #expect(settings.level == .normal)
        #expect(settings.splitArgument == nil)

        settings.splitPreset = .mb100
        #expect(settings.splitArgument == "100m")

        settings.splitPreset = .custom
        settings.customSplitMB = 250
        #expect(settings.splitArgument == "250m")
    }
}
