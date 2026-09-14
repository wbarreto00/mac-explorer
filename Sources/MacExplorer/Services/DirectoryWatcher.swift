import Foundation

final class DirectoryWatcher {
    private var source: DispatchSourceFileSystemObject?
    private var generation = UUID()
    func watch(_ url: URL, changed: @escaping () -> Void) {
        stop()
        let request = generation
        // Network/File Provider access and permission checks can block open().
        // Never perform that work while SwiftUI is creating the first window.
        DispatchQueue.global(qos: .utility).async { [weak self] in
            let descriptor = open(url.path, O_EVTONLY)
            guard descriptor >= 0 else { return }
            DispatchQueue.main.async { [weak self] in
                guard let self, self.generation == request else { close(descriptor); return }
                let source = DispatchSource.makeFileSystemObjectSource(fileDescriptor: descriptor, eventMask: [.write, .delete, .rename, .attrib, .extend], queue: .main)
                source.setEventHandler(handler: changed)
                source.setCancelHandler { close(descriptor) }
                self.source = source
                source.resume()
            }
        }
    }
    func stop() { generation = UUID(); source?.cancel(); source = nil }
    deinit { source?.cancel() }
}
