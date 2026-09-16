import SwiftUI
import AppKit
import ExplorerCore

struct PermissionsSettingsView: View {
    @State private var settingsUnavailable = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Label(L10n.text("permissions.title"), systemImage: "externaldrive.badge.checkmark")
                    .font(.headline)
                Text(L10n.text("permissions.description"))
                Text(L10n.text("permissions.scope"))
                    .foregroundStyle(.secondary)
                HStack {
                    Button(L10n.text("permissions.open")) { openSystemSettings() }
                        .buttonStyle(.borderedProminent)
                    Button(L10n.text("permissions.reveal_app")) {
                        NSWorkspace.shared.activateFileViewerSelecting([Bundle.main.bundleURL])
                    }
                }
                Text(L10n.text("permissions.instructions"))
                Text(L10n.text("permissions.update_hint"))
                    .font(.callout).foregroundStyle(.secondary)
            }
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(24)
        }
        .alert(L10n.text("permissions.open_error"), isPresented: $settingsUnavailable) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(L10n.text("permissions.manual_path"))
        }
    }

    private func openSystemSettings() {
        // Open the system-owned permission UI. Opening it does not grant access.
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles") else { return }
        settingsUnavailable = !NSWorkspace.shared.open(url)
    }
}
