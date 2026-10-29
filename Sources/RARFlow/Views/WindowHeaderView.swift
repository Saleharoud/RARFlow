import SwiftUI
import AppKit

public struct WindowHeaderView: View {
    @Bindable var appState: AppState

    public var body: some View {
        HStack(spacing: 0) {
            // Left margin reserving space for native traffic light controls (close/min/zoom)
            Spacer()
                .frame(width: 80)

            Spacer()

            // Center: Archive Title & Format Details
            HStack(spacing: 8) {
                Image(systemName: "archivebox.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(RARFlowTheme.accentCyan)

                if let activeURL = appState.activeArchiveURL {
                    let metaInfo: String = {
                        if let meta = appState.archiveMetadata {
                            return " (\(meta.formatName)\(meta.isSolid ? " Solid" : ""))"
                        } else {
                            return " (\(activeURL.pathExtension.uppercased()))"
                        }
                    }()

                    Text("RARFlow — \(activeURL.lastPathComponent)\(metaInfo)")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(RARFlowTheme.textPrimary)
                        .lineLimit(1)
                } else {
                    Text("RARFlow — Archive Suite")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(RARFlowTheme.textSecondary)
                }
            }

            Spacer()

            // Right: Tag Status Pill (Size & Compression Ratio)
            HStack(spacing: 6) {
                if let meta = appState.archiveMetadata {
                    Text("\(meta.humanReadablePhysicalSize) • \(meta.overallRatioString) Ratio")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundStyle(RARFlowTheme.textSecondary)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 3)
                        .background(RARFlowTheme.bgPill)
                        .overlay(
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(RARFlowTheme.borderSubtle, lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                } else {
                    Text("Ready")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(RARFlowTheme.textMuted)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(RARFlowTheme.bgPill)
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                }
            }
            .frame(width: 170, alignment: .trailing)
        }
        .padding(.horizontal, 14)
        .frame(height: 38)
        .background(RARFlowTheme.bgHeader)
        .background(WindowDragRepresentable())
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundStyle(RARFlowTheme.borderSubtle),
            alignment: .bottom
        )
    }
}

private struct WindowDragRepresentable: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = DragView()
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}

    final class DragView: NSView {
        override var mouseDownCanMoveWindow: Bool { true }
    }
}
