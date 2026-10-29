import SwiftUI

public struct ProgressOverlayView: View {
    @Bindable var appState: AppState

    public var body: some View {
        ZStack {
            Color.black.opacity(0.65)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                HStack(spacing: 12) {
                    ProgressView()
                        .controlSize(.regular)
                    Text(appState.busyTitle)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(RARFlowTheme.textPrimary)
                    Spacer()
                }

                ProgressView(value: appState.progress)
                    .progressViewStyle(.linear)
                    .tint(RARFlowTheme.accentBlue)

                HStack {
                    Text(appState.progressDetail)
                        .font(.system(size: 12))
                        .foregroundStyle(RARFlowTheme.textSecondary)
                        .lineLimit(1)
                        .truncationMode(.middle)

                    Spacer()

                    Text(String(format: "%.0f%%", appState.progress * 100))
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundStyle(RARFlowTheme.accentCyan)
                }

                HStack {
                    Spacer()
                    Button("Cancel") {
                        appState.cancelCurrentOperation()
                    }
                    .buttonStyle(.plain)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(RARFlowTheme.textSecondary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(RARFlowTheme.bgPill)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .keyboardShortcut(.cancelAction)
                }
            }
            .padding(24)
            .frame(width: 440)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(RARFlowTheme.bgHeader)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(RARFlowTheme.borderMedium, lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.4), radius: 24, x: 0, y: 12)
            )
        }
    }
}
