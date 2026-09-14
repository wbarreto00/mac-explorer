import Foundation

/// All app-authored text uses the same language in SwiftUI, AppKit and the core.
/// English is the first-run default; users may opt in to the macOS language.
public enum L10n {
    public static let supportedLanguages = ["en", "pt-BR", "es"]
    public static let preferenceKey = "MacExplorerLanguage"
    public static let language = selectedLanguage(UserDefaults.standard.string(forKey: preferenceKey), systemLanguages: Locale.preferredLanguages)

    public static func selectedLanguage(_ preference: String?, systemLanguages: [String]) -> String {
        if preference == "system" { return resolveLanguage(systemLanguages) }
        return supportedLanguages.contains(preference ?? "") ? preference! : "en"
    }

    /// Run before SwiftUI starts so native menus and dialogs use the same language.
    public static func configureNativeLanguage(defaults: UserDefaults = .standard) {
        let preference = defaults.string(forKey: preferenceKey)
        if preference == "system" {
            defaults.removeObject(forKey: "AppleLanguages")
        } else {
            defaults.set([selectedLanguage(preference, systemLanguages: [])], forKey: "AppleLanguages")
        }
    }

    public static func resolveLanguage(_ preferences: [String]) -> String {
        for preference in preferences {
            let base = preference.replacingOccurrences(of: "_", with: "-").lowercased().split(separator: "-").first
            switch base {
            case "en": return "en"
            case "pt": return "pt-BR"
            case "es": return "es"
            default: continue
            }
        }
        return "en"
    }

    public static let resources: Bundle = {
        // The app loads its signed resources. CLI checks load the adjacent bundle.
        // Avoid SwiftPM's generated accessor, which embeds a developer's path.
        if let url = Bundle.main.resourceURL?.appendingPathComponent("MacExplorer_ExplorerCore.bundle"),
           let bundled = Bundle(url: url) { return bundled }
        let executable = URL(fileURLWithPath: CommandLine.arguments[0]).resolvingSymlinksInPath()
        let adjacent = executable.deletingLastPathComponent().appendingPathComponent("MacExplorer_ExplorerCore.bundle")
        if let bundled = Bundle(url: adjacent) { return bundled }
        fatalError("Mac Explorer language resources are missing. Rebuild or reinstall the complete app bundle.")
    }()

    public static func text(_ key: String, language: String = language) -> String {
        guard let bundle = catalogBundle(for: language) else { return key }
        return bundle.localizedString(forKey: key, value: nil, table: "Localizable")
    }

    public static func catalogBundle(for language: String) -> Bundle? {
        let chosen = resolveLanguage([language])
        // SwiftPM normalizes language directory names (pt-BR becomes pt-br).
        for name in [chosen, chosen.lowercased()] {
            if let path = resources.path(forResource: name, ofType: "lproj"), let bundle = Bundle(path: path) { return bundle }
        }
        return nil
    }

    public static func format(_ key: String, _ arguments: CVarArg...) -> String {
        String(format: text(key), locale: Locale.autoupdatingCurrent, arguments: arguments)
    }

    /// English, Brazilian Portuguese and Spanish use singular for one item.
    public static func count(_ key: String, _ number: Int, language: String = language) -> String {
        String(format: text(key + (number == 1 ? ".one" : ".other"), language: language),
               locale: Locale.autoupdatingCurrent, arguments: [Int64(number)])
    }
}
