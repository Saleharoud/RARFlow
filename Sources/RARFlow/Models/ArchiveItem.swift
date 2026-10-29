import Foundation
import SwiftUI

public struct ArchiveItem: Identifiable, Hashable, Sendable {
    public let id: String
    public let path: String
    public let filename: String
    public let isDirectory: Bool
    public let uncompressedSize: Int64
    public let compressedSize: Int64
    public let modifiedDate: Date?
    public let attributes: String?
    public let crc32: String?
    public let isEncrypted: Bool
    public let method: String?

    public init(
        id: String = UUID().uuidString,
        path: String,
        filename: String? = nil,
        isDirectory: Bool,
        uncompressedSize: Int64 = 0,
        compressedSize: Int64 = 0,
        modifiedDate: Date? = nil,
        attributes: String? = nil,
        crc32: String? = nil,
        isEncrypted: Bool = false,
        method: String? = nil
    ) {
        self.id = id
        self.path = path
        self.filename = filename ?? (path as NSString).lastPathComponent
        self.isDirectory = isDirectory
        self.uncompressedSize = uncompressedSize
        self.compressedSize = compressedSize
        self.modifiedDate = modifiedDate
        self.attributes = attributes
        self.crc32 = crc32
        self.isEncrypted = isEncrypted
        self.method = method
    }

    public var humanReadableSize: String {
        if isDirectory { return "--" }
        return ByteCountFormatter.string(fromByteCount: uncompressedSize, countStyle: .file)
    }

    public var humanReadableCompressedSize: String {
        if isDirectory || compressedSize <= 0 { return "--" }
        return ByteCountFormatter.string(fromByteCount: compressedSize, countStyle: .file)
    }

    public var ratioDouble: Double? {
        guard !isDirectory, uncompressedSize > 0, compressedSize > 0 else { return nil }
        return Double(compressedSize) / Double(uncompressedSize) * 100.0
    }

    public var compressionRatioString: String {
        guard let ratio = ratioDouble else { return "--" }
        return String(format: "%.1f%%", ratio)
    }

    public var formattedDate: String {
        guard let date = modifiedDate else { return "--" }
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "HH:mm"
            return "Today \(timeFormatter.string(from: date))"
        } else if calendar.isDateInYesterday(date) {
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "HH:mm"
            return "Yesterday \(timeFormatter.string(from: date))"
        } else {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMM d, yyyy"
            return dateFormatter.string(from: date)
        }
    }

    public var systemIconName: String {
        if isDirectory { return "folder.fill" }
        let ext = (filename as NSString).pathExtension.lowercased()
        switch ext {
        case "jpg", "jpeg", "png", "gif", "webp", "heic", "tiff", "bmp", "svg":
            return "photo.fill"
        case "mp4", "mov", "mkv", "avi", "webm", "m4v":
            return "film.fill"
        case "mp3", "m4a", "flac", "wav", "aac", "ogg":
            return "music.note"
        case "pdf":
            return "doc.text.fill"
        case "txt", "md", "rtf", "log":
            return "doc.plaintext.fill"
        case "swift", "py", "js", "ts", "c", "cpp", "h", "java", "html", "css", "json", "xml", "sh":
            return "chevron.left.forwardslash.chevron.right"
        case "zip", "rar", "7z", "tar", "gz", "bz2", "xz":
            return "archivebox.fill"
        case "key", "pem", "crt", "env", "token", "secret":
            return "lock.fill"
        case "dmg", "iso", "img":
            return "opticaldisc.fill"
        case "app":
            return "app.badge.fill"
        default:
            return "doc.fill"
        }
    }

    public var iconColor: Color {
        if isDirectory { return Color(red: 0.22, green: 0.74, blue: 0.97) }
        let ext = (filename as NSString).pathExtension.lowercased()
        switch ext {
        case "jpg", "jpeg", "png", "gif", "webp", "heic", "tiff", "bmp", "svg":
            return Color(red: 0.06, green: 0.73, blue: 0.51)
        case "mp4", "mov", "mkv", "avi", "webm", "m4v":
            return Color(red: 0.96, green: 0.25, blue: 0.37)
        case "mp3", "m4a", "flac", "wav", "aac", "ogg":
            return Color(red: 0.66, green: 0.33, blue: 0.97)
        case "pdf":
            return Color(red: 0.38, green: 0.65, blue: 0.98)
        case "key", "pem", "crt", "env", "token", "secret":
            return Color(red: 0.98, green: 0.75, blue: 0.14)
        case "zip", "rar", "7z", "tar", "gz", "bz2", "xz":
            return Color(red: 0.98, green: 0.45, blue: 0.09)
        default:
            return Color(red: 0.60, green: 0.68, blue: 0.78)
        }
    }
}
