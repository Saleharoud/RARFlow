import SwiftUI

public struct PasswordSheetView: View {
    @Bindable var appState: AppState
    @State private var passwordText: String = ""
    @State private var showPasswordPlain: Bool = false

    public var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 48))
                .foregroundStyle(.tint)

            VStack(spacing: 6) {
                Text(appState.passwordPromptTitle)
                    .font(.title3.bold())
                Text("This archive is protected with encryption. Please enter the password to proceed.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 340)
            }

            HStack(spacing: 8) {
                if showPasswordPlain {
                    TextField("Enter password", text: $passwordText)
                        .textFieldStyle(.roundedBorder)
                } else {
                    SecureField("Enter password", text: $passwordText)
                        .textFieldStyle(.roundedBorder)
                }

                Button {
                    showPasswordPlain.toggle()
                } label: {
                    Image(systemName: showPasswordPlain ? "eye.slash" : "eye")
                }
                .buttonStyle(.borderless)
            }
            .frame(width: 300)

            HStack(spacing: 12) {
                Button("Cancel") {
                    appState.showPasswordPrompt = false
                    appState.pendingPasswordAction = nil
                }
                .keyboardShortcut(.cancelAction)

                Button("Unlock") {
                    submitPassword()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                .disabled(passwordText.isEmpty)
            }
        }
        .padding(32)
        .frame(width: 400)
    }

    private func submitPassword() {
        let entered = passwordText
        appState.showPasswordPrompt = false
        if let action = appState.pendingPasswordAction {
            appState.pendingPasswordAction = nil
            action(entered)
        }
    }
}
