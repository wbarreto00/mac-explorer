import Foundation

/// Favorites are ordered references. Reading/saving them never changes files.
public enum FavoriteFolders {
    public static func normalized(_ urls: [URL]) -> [URL] {
        var paths = Set<String>()
        return urls.filter(\.isFileURL).map(\.standardizedFileURL).filter { paths.insert($0.path).inserted }
    }

    /// Call off the UI thread: a mounted or cloud volume can respond slowly.
    public static func directories(in urls: [URL]) -> [URL] {
        normalized(urls).filter { url in
            guard let values = try? url.resourceValues(forKeys: [.isDirectoryKey, .isPackageKey]) else { return false }
            return values.isDirectory == true && values.isPackage != true
        }
    }

    public static func adding(_ urls: [URL], to favorites: [URL]) -> [URL] {
        normalized(favorites + urls)
    }

    public static func removing(_ urls: [URL], from favorites: [URL]) -> [URL] {
        let removed = Set(normalized(urls).map(\.path))
        return normalized(favorites).filter { !removed.contains($0.path) }
    }

    public static func load(from defaults: UserDefaults, fallback: [URL]) -> [URL] {
        // Retain disconnected favorites and distinguish an empty list from first run.
        guard let paths = defaults.stringArray(forKey: "favorites") else { return normalized(fallback) }
        return normalized(paths.map { URL(fileURLWithPath: $0) })
    }

    public static func save(_ urls: [URL], to defaults: UserDefaults) {
        defaults.set(normalized(urls).map(\.path), forKey: "favorites")
    }
}
