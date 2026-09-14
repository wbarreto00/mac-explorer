import AppKit
import UniformTypeIdentifiers

enum DropFiles {
    @MainActor static func accept(_ providers: [NSItemProvider], folder: URL, tab: BrowserTab) -> Bool {
        guard !Operations.shared.busy, !providers.isEmpty else { return false }
        Task {
            var urls: [URL] = []
            for provider in providers {
                let url: URL? = await withCheckedContinuation { continuation in
                    provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { value, _ in
                        if let data = value as? Data { continuation.resume(returning: URL(dataRepresentation: data, relativeTo: nil)) }
                        else if let url = value as? URL { continuation.resume(returning: url) }
                        else { continuation.resume(returning: nil) }
                    }
                }
                if let url, url.isFileURL { urls.append(url) }
            }
            Operations.shared.transfer(urls, into: folder, moving: false, tab: tab)
        }
        return true
    }
}
