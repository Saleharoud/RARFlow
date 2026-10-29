import Foundation
import UniformTypeIdentifiers

public enum ArchiveFormat: String, CaseIterable, Identifiable, Sendable {
    case rar = "rar"
    case sevenZip = "7z"
    case zip = "zip"
    case tar = "tar"
    case gzip = "tar.gz"
    case bzip2 = "tar.bz2"
    case xz = "tar.xz"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .rar: return "RAR Archive (.rar)"
        case .sevenZip: return "7-Zip Archive (.7z)"
        case .zip: return "ZIP Archive (.zip)"
        case .tar: return "TAR Archive (.tar)"
        case .gzip: return "GZip Tarball (.tar.gz)"
        case .bzip2: return "BZip2 Tarball (.tar.bz2)"
        case .xz: return "XZ Tarball (.tar.xz)"
        }
    }

    public var fileExtension: String {
        switch self {
        case .rar: return "rar"
        case .sevenZip: return "7z"
        case .zip: return "zip"
        case .tar: return "tar"
        case .gzip: return "tar.gz"
        case .bzip2: return "tar.bz2"
        case .xz: return "tar.xz"
        }
    }

    public var canCompress: Bool {
        switch self {
        case .rar:
            return HelperLocator.findRarExecutable() != nil
        case .sevenZip, .zip, .tar, .gzip, .bzip2, .xz:
            return true
        }
    }

    public var iconName: String {
        switch self {
        case .rar: return "archivebox.fill"
        case .sevenZip: return "archivebox"
        case .zip: return "doc.zipper"
        case .tar, .gzip, .bzip2, .xz: return "shippingbox.fill"
        }
    }

    public static func detect(from url: URL) -> ArchiveFormat? {
        let name = url.lastPathComponent.lowercased()
        if name.hasSuffix(".tar.gz") || name.hasSuffix(".tgz") { return .gzip }
        if name.hasSuffix(".tar.bz2") || name.hasSuffix(".tbz2") { return .bzip2 }
        if name.hasSuffix(".tar.xz") || name.hasSuffix(".txz") { return .xz }
        if name.hasSuffix(".rar") || name.hasSuffix(".r00") || name.hasSuffix(".cbr") { return .rar }
        if name.hasSuffix(".7z") || name.hasSuffix(".cb7") { return .sevenZip }
        if name.hasSuffix(".zip") || name.hasSuffix(".zipx") || name.hasSuffix(".cbz") { return .zip }
        if name.hasSuffix(".tar") { return .tar }
        return nil
    }

    public static var creationFormats: [ArchiveFormat] {
        if HelperLocator.findRarExecutable() != nil {
            return [.rar, .sevenZip, .zip, .tar, .gzip, .bzip2, .xz]
        }
        return [.sevenZip, .zip, .tar, .gzip, .bzip2, .xz]
    }
}
