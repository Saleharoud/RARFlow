import SwiftUI

public struct MainView: View {
    @Bindable var appState: AppState

    public var body: some View {
        NavigationSplitView {
            SidebarView(appState: appState)
        } detail: {
            detailContent
        }
        .sheet(isPresented: $appState.showCompressSheet) {
            CompressDialogView(appState: appState)
        }
        .sheet(isPresented: $appState.showExtractPromptDialog) {
            ExtractPromptSheetView(appState: appState)
        }
        .sheet(isPresented: $appState.showPasswordPrompt) {
            PasswordSheetView(appState: appState)
        }
        .overlay {
            if appState.isBusy {
                ProgressOverlayView(appState: appState)
            }
        }
        .alert("Notice", isPresented: $appState.showAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(appState.alertMessage ?? "")
        }
        .alert("Error", isPresented: $appState.showErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(appState.errorMessage ?? "An unexpected error occurred.")
        }
    }

    @ViewBuilder
    private var detailContent: some View {
        switch appState.selectedSection {
        case .dropZone:
            QuickDropZoneView(appState: appState)
        case .browser:
            ArchiveBrowserView(appState: appState)
        case .newArchive:
            QuickDropZoneView(appState: appState)
        case .settings:
            SettingsView(appState: appState)
        }
    }
}
