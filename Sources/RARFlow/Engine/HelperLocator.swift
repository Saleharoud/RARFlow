import Foundation

public struct HelperLocator: Sendable {
    public static func findSevenZip() -> URL? {
        // 1. Inside App Bundle Contents/Helpers/
        if let bundleHelpers = Bundle.main.bundlePath as String? {
            let helperURL = URL(fileURLWithPath: bundleHelpers)
                .appendingPathComponent("Contents/Helpers/7zz")
            if FileManager.default.isExecutableFile(atPath: helperURL.path) {
                return helperURL
            }
        }

        // 2. Local App relative directory (for development or portable mode)
        let localHelper = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("Helpers/7zz")
        if FileManager.default.isExecutableFile(atPath: localHelper.path) {
            return localHelper
        }

        // 3. Standard Homebrew & System paths
        let standardPaths = [
            "/opt/homebrew/bin/7zz",
            "/usr/local/bin/7zz",
            "/opt/homebrew/bin/7z",
            "/usr/local/bin/7z"
        ]
        for path in standardPaths {
            if FileManager.default.isExecutableFile(atPath: path) {
                return URL(fileURLWithPath: path)
            }
        }

        return nil
    }

    public static func findLsar() -> URL? {
        if let bundleHelpers = Bundle.main.bundlePath as String? {
            let helperURL = URL(fileURLWithPath: bundleHelpers)
                .appendingPathComponent("Contents/Helpers/lsar")
            if FileManager.default.isExecutableFile(atPath: helperURL.path) {
                return helperURL
            }
        }

        let localHelper = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("Helpers/lsar")
        if FileManager.default.isExecutableFile(atPath: localHelper.path) {
            return localHelper
        }

        let standardPaths = [
            "/opt/homebrew/bin/lsar",
            "/usr/local/bin/lsar"
        ]
        for path in standardPaths {
            if FileManager.default.isExecutableFile(atPath: path) {
                return URL(fileURLWithPath: path)
            }
        }

        return nil
    }

    public static func findUnar() -> URL? {
        if let bundleHelpers = Bundle.main.bundlePath as String? {
            let helperURL = URL(fileURLWithPath: bundleHelpers)
                .appendingPathComponent("Contents/Helpers/unar")
            if FileManager.default.isExecutableFile(atPath: helperURL.path) {
                return helperURL
            }
        }

        let localHelper = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("Helpers/unar")
        if FileManager.default.isExecutableFile(atPath: localHelper.path) {
            return localHelper
        }

        let standardPaths = [
            "/opt/homebrew/bin/unar",
            "/usr/local/bin/unar"
        ]
        for path in standardPaths {
            if FileManager.default.isExecutableFile(atPath: path) {
                return URL(fileURLWithPath: path)
            }
        }

        return nil
    }

    public static func findUnrarExecutable() -> URL? {
        if let bundleHelpers = Bundle.main.bundlePath as String? {
            let helperURL = URL(fileURLWithPath: bundleHelpers)
                .appendingPathComponent("Contents/Helpers/unrar")
            if FileManager.default.isExecutableFile(atPath: helperURL.path) {
                return helperURL
            }
        }

        let localHelper = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("Helpers/unrar")
        if FileManager.default.isExecutableFile(atPath: localHelper.path) {
            return localHelper
        }

        let standardPaths = [
            "/usr/local/bin/unrar",
            "/opt/homebrew/bin/unrar"
        ]
        for path in standardPaths {
            if FileManager.default.isExecutableFile(atPath: path) {
                return URL(fileURLWithPath: path)
            }
        }

        return nil
    }

    public static func findRarExecutable() -> URL? {
        // 1. Inside App Bundle Contents/Helpers/
        if let bundleHelpers = Bundle.main.bundlePath as String? {
            let helperURL = URL(fileURLWithPath: bundleHelpers)
                .appendingPathComponent("Contents/Helpers/rar")
            if FileManager.default.isExecutableFile(atPath: helperURL.path) {
                return helperURL
            }
        }

        // 2. Local relative directory
        let localHelper = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("Helpers/rar")
        if FileManager.default.isExecutableFile(atPath: localHelper.path) {
            return localHelper
        }

        // 3. User custom configured path in UserDefaults
        if let customPath = UserDefaults.standard.string(forKey: "customRarBinaryPath"),
           !customPath.isEmpty,
           FileManager.default.isExecutableFile(atPath: customPath) {
            return URL(fileURLWithPath: customPath)
        }

        let standardPaths = [
            "/usr/local/bin/rar",
            "/opt/homebrew/bin/rar"
        ]
        for path in standardPaths {
            if FileManager.default.isExecutableFile(atPath: path) {
                return URL(fileURLWithPath: path)
            }
        }

        return nil
    }
}
