import SwiftUI
import ExplorerCore

struct AppSettingsView: View {
    var body: some View {
        TabView {
            LanguageSettingsView()
                .tabItem { Label(L10n.text("settings.language"), systemImage: "character.bubble") }
            PermissionsSettingsView()
                .tabItem { Label(L10n.text("settings.permissions"), systemImage: "lock.shield") }
        }
        .frame(width: 560, height: 450)
    }
}
