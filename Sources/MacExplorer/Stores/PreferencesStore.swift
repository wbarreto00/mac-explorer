import Foundation
import ExplorerCore

@MainActor
final class PreferencesStore: ObservableObject {
    static let shared = PreferencesStore()
    @Published private(set) var favorites: [URL] = []
    private let defaults = UserDefaults.standard
    private var folderSettings: [String: FolderPreferences] = [:]
    private var defaultSettings = FolderPreferences()

    private init() {
        if let data = defaults.data(forKey: "folderSettings"), let saved = try? JSONDecoder().decode([String: FolderPreferences].self, from: data) { folderSettings = saved }
        if let data = defaults.data(forKey: "defaultSettings"), let saved = try? JSONDecoder().decode(FolderPreferences.self, from: data) { defaultSettings = saved }
        let home = FileManager.default.homeDirectoryForCurrentUser
        let initial = [home, home.appendingPathComponent("Desktop"), home.appendingPathComponent("Documents"), home.appendingPathComponent("Downloads"), home.appendingPathComponent("Pictures")].filter { FileManager.default.fileExists(atPath: $0.path) }
        favorites = FavoriteFolders.load(from: defaults, fallback: initial)
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
        if isFavorite(url) { removeFavorites([url]) } else { addFavorites([url]) }
    }
    func isFavorite(_ url: URL) -> Bool { favorites.contains { $0.path == url.standardizedFileURL.path } }
    func addFavorites(_ urls: [URL]) {
        Task {
            let folders = await Task.detached(priority: .userInitiated) { FavoriteFolders.directories(in: urls) }.value
            let updated = FavoriteFolders.adding(folders, to: favorites)
            let count = updated.count - favorites.count
            favorites = updated
            FavoriteFolders.save(favorites, to: defaults)
            if !Operations.shared.busy {
                Operations.shared.status = folders.isEmpty ? L10n.text("favorite.folders_only") : (count == 0 ? L10n.text("favorite.already_added") : L10n.count("count.favorites_added", count))
            }
        }
    }
    func removeFavorites(_ urls: [URL]) {
        favorites = FavoriteFolders.removing(urls, from: favorites)
        FavoriteFolders.save(favorites, to: defaults)
    }
}
