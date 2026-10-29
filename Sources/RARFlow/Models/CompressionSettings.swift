import Foundation

public enum CompressionLevel: Int, CaseIterable, Identifiable, Sendable {
    case store = 0
    case fastest = 1
    case fast = 3
    case normal = 5
    case maximum = 7
    case ultra = 9

    public var id: Int { rawValue }

    public var title: String {
        switch self {
        case .store: return "Store (0 - No compression)"
        case .fastest: return "Fastest (1)"
        case .fast: return "Fast (3)"
        case .normal: return "Normal (5 - Recommended)"
        case .maximum: return "Maximum (7)"
        case .ultra: return "Ultra (9 - Highest ratio)"
        }
    }

    public var shortName: String {
        switch self {
        case .store: return "Store"
        case .fastest: return "Fastest"
        case .fast: return "Fast"
        case .normal: return "Normal"
        case .maximum: return "Maximum"
        case .ultra: return "Ultra"
        }
    }
}

public enum CompressionMethod: String, CaseIterable, Identifiable, Sendable {
    case lzma2 = "LZMA2"
    case lzma = "LZMA"
    case deflate = "Deflate"
    case deflate64 = "Deflate64"
    case bzip2 = "BZip2"
    case ppmd = "PPMd"

    public var id: String { rawValue }

    public var switchValue: String {
        switch self {
        case .lzma2: return "LZMA2"
        case .lzma: return "LZMA"
        case .deflate: return "Deflate"
        case .deflate64: return "Deflate64"
        case .bzip2: return "BZip2"
        case .ppmd: return "PPMd"
        }
    }
}

public enum SplitVolumePreset: String, CaseIterable, Identifiable, Sendable {
    case none = "None (Single Archive)"
    case mb10 = "10 MB"
    case mb100 = "100 MB"
    case mb700 = "700 MB (CD-R)"
    case mb1000 = "1,000 MB (1 GB)"
    case mb4000 = "4,000 MB (FAT32 limit)"
    case mb4700 = "4.7 GB (DVD)"
    case mb25000 = "25 GB (Blu-Ray)"
    case custom = "Custom Size..."

    public var id: String { rawValue }

    public var switchArgument: String? {
        switch self {
        case .none: return nil
        case .mb10: return "10m"
        case .mb100: return "100m"
        case .mb700: return "700m"
        case .mb1000: return "1000m"
        case .mb4000: return "4000m"
        case .mb4700: return "4480m"
        case .mb25000: return "24000m"
        case .custom: return nil
        }
    }
}

public struct CompressionSettings: Sendable {
    public var format: ArchiveFormat
    public var level: CompressionLevel
    public var method: CompressionMethod
    public var password: String
    public var encryptHeader: Bool
    public var splitPreset: SplitVolumePreset
    public var customSplitMB: Int
    public var excludeMacMetadata: Bool
    public var isSolid: Bool
    public var threadCount: Int
    public var deleteSourceAfter: Bool

    public init(
        format: ArchiveFormat = .sevenZip,
        level: CompressionLevel = .normal,
        method: CompressionMethod = .lzma2,
        password: String = "",
        encryptHeader: Bool = false,
        splitPreset: SplitVolumePreset = .none,
        customSplitMB: Int = 100,
        excludeMacMetadata: Bool = true,
        isSolid: Bool = true,
        threadCount: Int = ProcessInfo.processInfo.activeProcessorCount,
        deleteSourceAfter: Bool = false
    ) {
        self.format = format
        self.level = level
        self.method = method
        self.password = password
        self.encryptHeader = encryptHeader
        self.splitPreset = splitPreset
        self.customSplitMB = customSplitMB
        self.excludeMacMetadata = excludeMacMetadata
        self.isSolid = isSolid
        self.threadCount = threadCount
        self.deleteSourceAfter = deleteSourceAfter
    }

    public var splitArgument: String? {
        if splitPreset == .custom && customSplitMB > 0 {
            return "\(customSplitMB)m"
        }
        return splitPreset.switchArgument
    }
}
