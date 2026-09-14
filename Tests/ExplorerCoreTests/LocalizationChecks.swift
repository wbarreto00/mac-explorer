import Foundation
import ExplorerCore

extension ExplorerCoreTests {
    func testDefaultAndSelectedLanguage() throws {
        XCTAssertEqual(L10n.selectedLanguage(nil, systemLanguages: ["pt-BR"]), "en")
        XCTAssertEqual(L10n.selectedLanguage("invalid", systemLanguages: ["es"]), "en")
        XCTAssertEqual(L10n.selectedLanguage("en", systemLanguages: ["pt-BR"]), "en")
        XCTAssertEqual(L10n.selectedLanguage("pt-BR", systemLanguages: ["en"]), "pt-BR")
        XCTAssertEqual(L10n.selectedLanguage("es", systemLanguages: ["en"]), "es")
        XCTAssertEqual(L10n.selectedLanguage("system", systemLanguages: ["pt-PT"]), "pt-BR")
        XCTAssertEqual(L10n.selectedLanguage("system", systemLanguages: ["ja"]), "en")
        let domain = "MacExplorerLanguageTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: domain)!
        defer { defaults.removePersistentDomain(forName: domain) }
        L10n.configureNativeLanguage(defaults: defaults)
        XCTAssertEqual(defaults.stringArray(forKey: "AppleLanguages"), ["en"])
        defaults.set("es", forKey: L10n.preferenceKey)
        L10n.configureNativeLanguage(defaults: defaults)
        XCTAssertEqual(defaults.stringArray(forKey: "AppleLanguages"), ["es"])
        defaults.set("system", forKey: L10n.preferenceKey)
        L10n.configureNativeLanguage(defaults: defaults)
        XCTAssertFalse(defaults.persistentDomain(forName: domain)?.keys.contains("AppleLanguages") ?? false)
    }

    func testLanguageResolution() {
        XCTAssertEqual(L10n.resolveLanguage(["en-GB"]), "en")
        XCTAssertEqual(L10n.resolveLanguage(["pt_BR"]), "pt-BR")
        XCTAssertEqual(L10n.resolveLanguage(["pt-PT", "en"]), "pt-BR")
        XCTAssertEqual(L10n.resolveLanguage(["es-MX"]), "es")
        XCTAssertEqual(L10n.resolveLanguage(["fr-FR", "es-ES", "en"]), "es")
        XCTAssertEqual(L10n.resolveLanguage(["de-DE"]), "en")
        XCTAssertEqual(L10n.resolveLanguage([]), "en")
    }

    func testCompleteCatalogsAndFormatting() throws {
        let catalogs = try L10n.supportedLanguages.map { language -> [String: String] in
            guard let bundle = L10n.catalogBundle(for: language) else {
                throw NSError(domain: "Missing localization: \(language)", code: 1)
            }
            let data = try Data(contentsOf: bundle.bundleURL.appendingPathComponent("Localizable.strings"))
            guard let values = try PropertyListSerialization.propertyList(from: data, format: nil) as? [String: String] else {
                throw NSError(domain: "Invalid catalog: \(language)", code: 2)
            }
            XCTAssertTrue(values.count >= 180)
            for (key, value) in values {
                XCTAssertFalse(value.isEmpty)
                XCTAssertEqual(L10n.text(key, language: language), value)
                XCTAssertFalse(value.contains("Trilha"))
                XCTAssertFalse(value.contains("FolderPilot"))
            }
            return values
        }
        let token = try NSRegularExpression(pattern: "%(@|lld)")
        func placeholders(_ text: String) -> [String] {
            token.matches(in: text, range: NSRange(text.startIndex..., in: text)).map { (text as NSString).substring(with: $0.range) }.sorted()
        }
        for catalog in catalogs.dropFirst() {
            XCTAssertEqual(Set(catalog.keys), Set(catalogs[0].keys))
            for (key, value) in catalog { XCTAssertEqual(placeholders(value), placeholders(catalogs[0][key] ?? "")) }
        }
        XCTAssertEqual(L10n.text("action.new_folder", language: "en"), "New Folder")
        XCTAssertEqual(L10n.text("action.new_folder", language: "pt-BR"), "Nova pasta")
        XCTAssertEqual(L10n.text("action.new_folder", language: "es"), "Nueva carpeta")
    }

    func testLocalizedCounts() {
        XCTAssertEqual(L10n.count("count.items", 1, language: "en"), "1 item")
        XCTAssertEqual(L10n.count("count.items", 2, language: "en"), "2 items")
        XCTAssertEqual(L10n.count("count.items", 0, language: "pt-BR"), "0 itens")
        XCTAssertEqual(L10n.count("count.items", 1, language: "pt-BR"), "1 item")
        XCTAssertEqual(L10n.count("count.items", 2, language: "pt-BR"), "2 itens")
        XCTAssertEqual(L10n.count("count.items", 1, language: "es"), "1 elemento")
        XCTAssertEqual(L10n.count("count.items", 2, language: "es"), "2 elementos")
        XCTAssertEqual(L10n.count("count.trash", 1, language: "es"), "¿Mover 1 elemento a la Papelera?")
    }
}
