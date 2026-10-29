import SwiftUI

public struct PasswordSheetView: View {
    @Bindable var appState: AppState
    @State private var passwordText: String = ""
    @State private var showPasswordPlain: Bool = false

    public var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(RARFlowTheme.accentAmber.opacity(0.18))
                    .frame(width: 72, height: 72)
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(RARFlowTheme.accentAmber)
            }

            VStack(spacing: 6) {
                Text(appState.passwordPromptTitle)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(RARFlowTheme.textPrimary)
                Text("This archive is protected with encryption. Please enter the password to proceed.")
                    .font(.system(size: 12))
                    .foregroundStyle(RARFlowTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 320)
            }

            HStack(spacing: 8) {
                if showPasswordPlain {
                    TextField("Enter password", text: $passwordText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 13))
                        .foregroundStyle(RARFlowTheme.textPrimary)
                } else {
                    SecureField("Enter password", text: $passwordText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 13))
                        .foregroundStyle(RARFlowTheme.textPrimary)
                }

                Button {
                    showPasswordPlain.toggle()
                } label: {
                    Image(systemName: showPasswordPlain ? "eye.slash" : "eye")
                        .foregroundStyle(RARFlowTheme.textMuted)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .frame(width: 300)
            .background(RARFlowTheme.bgInput)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(RARFlowTheme.borderActive, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 6))

            HStack(spacing: 12) {
                Button("Cancel") {
                    appState.showPasswordPrompt = false
                    appState.pendingPasswordAction = nil
                }
                .buttonStyle(.plain)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(RARFlowTheme.textSecondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(RARFlowTheme.bgPill)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .keyboardShortcut(.cancelAction)

                Button("Unlock Archive") {
                    submitPassword()
                }
                .buttonStyle(.plain)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .background(passwordText.isEmpty ? Color.gray.opacity(0.3) : RARFlowTheme.accentBlue)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .shadow(color: passwordText.isEmpty ? .clear : RARFlowTheme.accentBlue.opacity(0.35), radius: 6, x: 0, y: 2)
                .keyboardShortcut(.defaultAction)
                .disabled(passwordText.isEmpty)
            }
        }
        .padding(30)
        .frame(width: 420)
        .background(RARFlowTheme.bgWindow)
    }

    private func submitPassword() {
        let pwd = passwordText
        appState.showPasswordPrompt = false
        if let action = appState.pendingPasswordAction {
            appState.pendingPasswordAction = nil
            action(pwd)
        }
    }
}
