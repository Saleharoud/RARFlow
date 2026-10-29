import Foundation

public struct SevenZipParser: Sendable {
    private static let dateFormatterFull: DateFormatter = {
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSSSSS"
        return df
    }()

    private static let dateFormatterShort: DateFormatter = {
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return df
    }()

    public static func parseSLTOutput(output: String, archiveURL: URL) -> (metadata: ArchiveMetadata, items: [ArchiveItem]) {
        let lines = output.components(separatedBy: .newlines)
        var isInArchiveHeaders = false
        var currentItemDict: [String: String] = [:]
        var items: [ArchiveItem] = []

        var archiveType = "Unknown"
        var physicalSize: Int64 = 0
        var isSolid = false
        var isEncrypted = false
        var volumesCount = 1
        var comment: String?

        var totalUncompressed: Int64 = 0
        var totalPacked: Int64 = 0
        var fileCount = 0
        var folderCount = 0

        func flushCurrentItem() {
            guard !currentItemDict.isEmpty else { return }
            guard let path = currentItemDict["Path"], !path.isEmpty else {
                currentItemDict.removeAll()
                return
            }

            let isDir = (currentItemDict["Folder"] == "+") ||
                        (currentItemDict["Attributes"]?.contains("D") == true) ||
                        path.hasSuffix("/")

            let uncompressedSize = Int64(currentItemDict["Size"] ?? "0") ?? 0
            let packedSize = Int64(currentItemDict["Packed Size"] ?? "0") ?? 0
            let modifiedStr = currentItemDict["Modified"] ?? ""
            let date = parseDate(modifiedStr)
            let attrs = currentItemDict["Attributes"]
            let crc = currentItemDict["CRC"]
            let itemEncrypted = currentItemDict["Encrypted"] == "+"
            let method = currentItemDict["Method"]

            if itemEncrypted {
                isEncrypted = true
            }

            if isDir {
                folderCount += 1
            } else {
                fileCount += 1
                totalUncompressed += uncompressedSize
                totalPacked += packedSize
            }

            let item = ArchiveItem(
                id: "\(path)_\(uncompressedSize)_\(date?.timeIntervalSince1970 ?? 0)",
                path: path,
                isDirectory: isDir,
                uncompressedSize: uncompressedSize,
                compressedSize: packedSize,
                modifiedDate: date,
                attributes: attrs,
                crc32: crc,
                isEncrypted: itemEncrypted,
                method: method
            )
            items.append(item)
            currentItemDict.removeAll()
        }

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed == "--" {
                isInArchiveHeaders = true
                continue
            }
            if trimmed == "----------" {
                isInArchiveHeaders = false
                flushCurrentItem()
                continue
            }
            if trimmed.isEmpty && !isInArchiveHeaders {
                flushCurrentItem()
                continue
            }

            if let equalIndex = line.firstIndex(of: "=") {
                let key = String(line[..<equalIndex]).trimmingCharacters(in: .whitespaces)
                let valueIndex = line.index(after: equalIndex)
                let value = String(line[valueIndex...]).trimmingCharacters(in: .whitespaces)

                if isInArchiveHeaders {
                    switch key {
                    case "Type":
                        archiveType = value
                    case "Physical Size":
                        physicalSize = Int64(value) ?? 0
                    case "Solid":
                        isSolid = (value == "+")
                    case "Volumes":
                        volumesCount = Int(value) ?? 1
                    case "Comment":
                        comment = value
                    default:
                        break
                    }
                } else {
                    if key == "Path" && currentItemDict["Path"] != nil {
                        flushCurrentItem()
                    }
                    currentItemDict[key] = value
                }
            }
        }

        flushCurrentItem()

        let detectedFormat = ArchiveFormat.detect(from: archiveURL)
        let metadata = ArchiveMetadata(
            archiveURL: archiveURL,
            format: detectedFormat,
            formatName: archiveType,
            totalPhysicalSize: physicalSize,
            totalUncompressedSize: totalUncompressed,
            totalPackedSize: totalPacked,
            fileCount: fileCount,
            folderCount: folderCount,
            isSolid: isSolid,
            isEncrypted: isEncrypted,
            volumesCount: volumesCount,
            comment: comment
        )

        return (metadata, items)
    }

    private static func parseDate(_ dateString: String) -> Date? {
        if let d = dateFormatterFull.date(from: dateString) {
            return d
        }
        return dateFormatterShort.date(from: dateString)
    }

    public static func parseProgressPercentage(from chunk: String) -> Double? {
        // Examples: " 45%", "100%", " 5% 120/400"
        let pattern = #"(\d{1,3})%"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(chunk.startIndex..<chunk.endIndex, in: chunk)
        let matches = regex.matches(in: chunk, range: range)
        if let lastMatch = matches.last,
           let percentRange = Range(lastMatch.range(at: 1), in: chunk),
           let percentVal = Double(chunk[percentRange]) {
            return min(max(percentVal / 100.0, 0.0), 1.0)
        }
        return nil
    }
}
