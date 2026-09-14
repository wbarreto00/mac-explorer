import SwiftUI
import ExplorerCore

struct LanguageSettingsView: View {
    @State private var selection = UserDefaults.standard.string(forKey: L10n.preferenceKey) ?? "en"

    var body: some View {
        Form {
            Picker(L10n.text("settings.language"), selection: $selection) {
                Text("English").tag("en")
                Text("Português (Brasil)").tag("pt-BR")
                Text("Español").tag("es")
                Text(L10n.text("settings.system_language")).tag("system")
            }
            .pickerStyle(.radioGroup)
            .onChange(of: selection) { _, value in
                UserDefaults.standard.set(value, forKey: L10n.preferenceKey)
                L10n.configureNativeLanguage()
            }
            Text(L10n.text("settings.restart_hint"))
                .font(.callout).foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(24)
        .frame(width: 420)
    }
}
