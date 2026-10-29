import Foundation

public struct LsarParser: Sendable {
    public static func parseJSONOutput(data: Data, archiveURL: URL) throws -> (metadata: ArchiveMetadata, items: [ArchiveItem]) {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw NSError(domain: "RARFlow", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON from lsar"])
        }

        let isoDateFormatter = ISO8601DateFormatter()
        let standardDateFormatter = DateFormatter()
        standardDateFormatter.locale = Locale(identifier: "en_US_POSIX")
        standardDateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"

        let formatName = json["lsarFormatName"] as? String ?? "Archive"
        let contents = json["lsarContents"] as? [[String: Any]] ?? []

        var items: [ArchiveItem] = []
        var totalUncompressed: Int64 = 0
        var totalPacked: Int64 = 0
        var fileCount = 0
        var folderCount = 0
        var isEncrypted = false

        for dict in contents {
            let filename = dict["XADFileName"] as? String ?? "unnamed"
            let isDir = (dict["XADIsDirectory"] as? Int == 1) || (dict["XADIsDirectory"] as? Bool == true) || filename.hasSuffix("/")
            let fileSize = (dict["XADFileSize"] as? NSNumber)?.int64Value ?? 0
            let packedSize = (dict["XADCompressedSize"] as? NSNumber)?.int64Value ?? 0
            let itemEncrypted = (dict["XADIsEncrypted"] as? Int == 1) || (dict["XADIsEncrypted"] as? Bool == true)
            let compName = dict["XADCompressionName"] as? String

            if itemEncrypted {
                isEncrypted = true
            }

            var date: Date?
            if let dateStr = dict["XADLastModificationDate"] as? String {
                date = standardDateFormatter.date(from: dateStr) ?? isoDateFormatter.date(from: dateStr)
            }

            if isDir {
                folderCount += 1
            } else {
                fileCount += 1
                totalUncompressed += fileSize
                totalPacked += packedSize
            }

            let item = ArchiveItem(
                id: "\(filename)_\(fileSize)_\(items.count)",
                path: filename,
                isDirectory: isDir,
                uncompressedSize: fileSize,
                compressedSize: packedSize,
                modifiedDate: date,
                attributes: nil,
                crc32: nil,
                isEncrypted: itemEncrypted,
                method: compName
            )
            items.append(item)
        }

        let physicalSize = (try? FileManager.default.attributesOfItem(atPath: archiveURL.path)[.size] as? NSNumber)?.int64Value ?? 0
        let metadata = ArchiveMetadata(
            archiveURL: archiveURL,
            format: ArchiveFormat.detect(from: archiveURL),
            formatName: formatName,
            totalPhysicalSize: physicalSize,
            totalUncompressedSize: totalUncompressed,
            totalPackedSize: totalPacked,
            fileCount: fileCount,
            folderCount: folderCount,
            isSolid: false,
            isEncrypted: isEncrypted,
            volumesCount: 1,
            comment: nil
        )

        return (metadata, items)
    }
}
