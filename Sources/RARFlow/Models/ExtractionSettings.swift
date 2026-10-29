import Foundation

public enum OverwritePolicy: String, CaseIterable, Identifiable, Sendable {
    case ask = "Ask for confirmation"
    case overwrite = "Overwrite existing files"
    case skip = "Skip existing files"

    public var id: String { rawValue }

    public var sevenZipSwitch: String {
        switch self {
        case .ask: return "-aoa" // Handled in UI or default overwrite
        case .overwrite: return "-aoa"
        case .skip: return "-aos"
        }
    }
}

public struct ExtractionSettings: Sendable {
    public var destinationURL: URL?
    public var overwritePolicy: OverwritePolicy
    public var createSubfolder: Bool
    public var revealInFinder: Bool
    public var playSound: Bool
    public var deleteArchiveAfter: Bool

    public init(
        destinationURL: URL? = nil,
        overwritePolicy: OverwritePolicy = .overwrite,
        createSubfolder: Bool = true,
        revealInFinder: Bool = true,
        playSound: Bool = true,
        deleteArchiveAfter: Bool = false
    ) {
        self.destinationURL = destinationURL
        self.overwritePolicy = overwritePolicy
        self.createSubfolder = createSubfolder
        self.revealInFinder = revealInFinder
        self.playSound = playSound
        self.deleteArchiveAfter = deleteArchiveAfter
    }
}
