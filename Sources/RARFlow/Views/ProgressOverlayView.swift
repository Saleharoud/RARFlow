import SwiftUI

public struct ProgressOverlayView: View {
    @Bindable var appState: AppState

    public var body: some View {
        ZStack {
            Color.black.opacity(0.35)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                HStack(spacing: 12) {
                    ProgressView()
                        .controlSize(.regular)
                    Text(appState.busyTitle)
                        .font(.headline)
                    Spacer()
                }

                ProgressView(value: appState.progress)
                    .progressViewStyle(.linear)

                HStack {
                    Text(appState.progressDetail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)

                    Spacer()

                    Text(String(format: "%.0f%%", appState.progress * 100))
                        .font(.caption.monospacedDigit().bold())
                        .foregroundStyle(.tint)
                }

                HStack {
                    Spacer()
                    Button("Cancel") {
                        appState.cancelCurrentOperation()
                    }
                    .keyboardShortcut(.cancelAction)
                }
            }
            .padding(24)
            .frame(width: 440)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(nsColor: .windowBackgroundColor))
                    .shadow(color: .black.opacity(0.25), radius: 20, x: 0, y: 10)
            )
        }
    }
}
