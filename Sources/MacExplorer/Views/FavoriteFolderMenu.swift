import SwiftUI
import ExplorerCore
import UniformTypeIdentifiers

struct FavoriteFolderMenu: View {
    let urls: [URL]
    @ObservedObject private var preferences = PreferencesStore.shared
    private var allSaved: Bool { urls.allSatisfy { preferences.isFavorite($0) } }

    var body: some View {
        if !urls.isEmpty {
            Button(L10n.text(allSaved ? "favorite.remove" : "favorite.add")) {
                if allSaved { preferences.removeFavorites(urls) }
                else { preferences.addFavorites(urls) }
            }
        }
    }
}

enum FavoriteDrop {
    @MainActor static func accept(_ providers: [NSItemProvider]) -> Bool {
        guard !providers.isEmpty else { return false }
        Task {
            var urls: [URL] = []
            for provider in providers {
                let url: URL? = await withCheckedContinuation { continuation in
                    provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { value, _ in
                        if let url = value as? URL { continuation.resume(returning: url) }
                        else if let data = value as? Data { continuation.resume(returning: URL(dataRepresentation: data, relativeTo: nil)) }
                        else { continuation.resume(returning: nil) }
                    }
                }
                if let url { urls.append(url) }
            }
            PreferencesStore.shared.addFavorites(urls)
        }
        return true
    }
}
