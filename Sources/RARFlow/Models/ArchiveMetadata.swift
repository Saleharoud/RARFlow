import Foundation

public struct ArchiveMetadata: Sendable {
    public let archiveURL: URL
    public let format: ArchiveFormat?
    public let formatName: String
    public let totalPhysicalSize: Int64
    public let totalUncompressedSize: Int64
    public let totalPackedSize: Int64
    public let fileCount: Int
    public let folderCount: Int
    public let isSolid: Bool
    public let isEncrypted: Bool
    public let volumesCount: Int
    public let comment: String?

    public init(
        archiveURL: URL,
        format: ArchiveFormat? = nil,
        formatName: String = "Archive",
        totalPhysicalSize: Int64 = 0,
        totalUncompressedSize: Int64 = 0,
        totalPackedSize: Int64 = 0,
        fileCount: Int = 0,
        folderCount: Int = 0,
        isSolid: Bool = false,
        isEncrypted: Bool = false,
        volumesCount: Int = 1,
        comment: String? = nil
    ) {
        self.archiveURL = archiveURL
        self.format = format ?? ArchiveFormat.detect(from: archiveURL)
        self.formatName = formatName
        self.totalPhysicalSize = totalPhysicalSize
        self.totalUncompressedSize = totalUncompressedSize
        self.totalPackedSize = totalPackedSize
        self.fileCount = fileCount
        self.folderCount = folderCount
        self.isSolid = isSolid
        self.isEncrypted = isEncrypted
        self.volumesCount = volumesCount
        self.comment = comment
    }

    public var humanReadablePhysicalSize: String {
        ByteCountFormatter.string(fromByteCount: totalPhysicalSize, countStyle: .file)
    }

    public var humanReadableUncompressedSize: String {
        ByteCountFormatter.string(fromByteCount: totalUncompressedSize, countStyle: .file)
    }

    public var overallRatioString: String {
        guard totalUncompressedSize > 0, totalPackedSize > 0 else { return "--" }
        let ratio = Double(totalPackedSize) / Double(totalUncompressedSize) * 100.0
        return String(format: "%.1f%%", ratio)
    }
}
