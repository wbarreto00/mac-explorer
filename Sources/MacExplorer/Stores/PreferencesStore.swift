import Foundation
import ExplorerCore

@MainActor
final class PreferencesStore: ObservableObject {
    static let shared = PreferencesStore()
    @Published var favorites: [URL] = []
    private let defaults = UserDefaults.standard
    private var folderSettings: [String: FolderPreferences] = [:]
    private var defaultSettings = FolderPreferences()

    private init() {
        if let data = defaults.data(forKey: "folderSettings"), let saved = try? JSONDecoder().decode([String: FolderPreferences].self, from: data) { folderSettings = saved }
        if let data = defaults.data(forKey: "defaultSettings"), let saved = try? JSONDecoder().decode(FolderPreferences.self, from: data) { defaultSettings = saved }
        if let paths = defaults.stringArray(forKey: "favorites") { favorites = paths.map { URL(fileURLWithPath: $0) } }
        else {
            let home = FileManager.default.homeDirectoryForCurrentUser
            favorites = [home, home.appendingPathComponent("Desktop"), home.appendingPathComponent("Documents"), home.appendingPathComponent("Downloads"), home.appendingPathComponent("Pictures")].filter { FileManager.default.fileExists(atPath: $0.path) }
        }
    }

    func settings(for url: URL) -> FolderPreferences { folderSettings[url.path] ?? defaultSettings }
    func save(_ settings: FolderPreferences, for url: URL) {
        folderSettings[url.path] = settings
        if let data = try? JSONEncoder().encode(folderSettings) { defaults.set(data, forKey: "folderSettings") }
    }
    func useAsDefault(_ settings: FolderPreferences) {
        defaultSettings = settings
        if let data = try? JSONEncoder().encode(settings) { defaults.set(data, forKey: "defaultSettings") }
    }
    func toggleFavorite(_ url: URL) {
        if favorites.contains(url) { favorites.removeAll { $0 == url } } else { favorites.append(url) }
        defaults.set(favorites.map(\.path), forKey: "favorites")
    }
}
