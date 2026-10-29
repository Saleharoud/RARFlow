import Foundation
import QuickLookUI
import AppKit

final class QuickLookPreviewItem: NSObject, QLPreviewItem, @unchecked Sendable {
    let previewItemURL: URL?
    let previewItemTitle: String?

    init(url: URL, title: String? = nil) {
        self.previewItemURL = url
        self.previewItemTitle = title ?? url.lastPathComponent
        super.init()
    }
}

public final class QuickLookPreviewController: NSObject, QLPreviewPanelDataSource, QLPreviewPanelDelegate, @unchecked Sendable {
    public static let shared = QuickLookPreviewController()
    private let lock = NSLock()
    private var _currentItem: QuickLookPreviewItem?

    private var currentItem: QuickLookPreviewItem? {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _currentItem
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            _currentItem = newValue
        }
    }

    @MainActor
    public func preview(fileURL: URL, title: String? = nil) {
        self.currentItem = QuickLookPreviewItem(url: fileURL, title: title)
        guard let panel = QLPreviewPanel.shared() else { return }
        panel.dataSource = self
        panel.delegate = self
        panel.makeKeyAndOrderFront(nil)
        panel.reloadData()
    }

    public nonisolated func numberOfPreviewItems(in panel: QLPreviewPanel!) -> Int {
        return currentItem == nil ? 0 : 1
    }

    public nonisolated func previewPanel(_ panel: QLPreviewPanel!, previewItemAt index: Int) -> QLPreviewItem! {
        return currentItem
    }
}
