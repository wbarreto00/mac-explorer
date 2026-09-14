import AppKit
import ExplorerCore

enum Display {
    static let date: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = .autoupdatingCurrent
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()
    static func size(_ item: FileEntry) -> String { item.navigable ? "" : ByteCountFormatter.string(fromByteCount: item.size, countStyle: .file) }
    static func folderName(_ url: URL) -> String {
        let home = FileManager.default.homeDirectoryForCurrentUser
        if url == home { return L10n.text("folder.home") }
        let names = ["Desktop": L10n.text("folder.desktop"), "Documents": L10n.text("folder.documents"), "Downloads": L10n.text("folder.downloads"), "Pictures": L10n.text("folder.pictures"), "Movies": L10n.text("folder.movies"), "Music": L10n.text("folder.music")]
        if url.deletingLastPathComponent() == home, let name = names[url.lastPathComponent] { return name }
        if url.path == "/Applications" { return L10n.text("folder.applications") }
        if url.path == "/" { return (try? url.resourceValues(forKeys: [.volumeLocalizedNameKey]).volumeLocalizedName) ?? "Macintosh HD" }
        return url.lastPathComponent
    }
    static func value(_ field: SortField, item: FileEntry, extensions: Bool) -> String {
        switch field {
        case .name: return item.displayName(showExtensions: extensions)
        case .modified: return date.string(from: item.modified)
        case .created: return date.string(from: item.created)
        case .added: return date.string(from: item.added)
        case .kind: return item.kind
        case .size: return size(item)
        case .fileExtension: return item.fileExtension
        case .tags: return item.tags.joined(separator: ", ")
        }
    }
}

@MainActor
enum Dialogs {
    static func text(title: String, message: String, value: String, action: String) -> String? {
        let alert = NSAlert()
        alert.messageText = title; alert.informativeText = message
        let field = NSTextField(string: value)
        field.frame = NSRect(x: 0, y: 0, width: 380, height: 26)
        alert.accessoryView = field
        alert.addButton(withTitle: action); alert.addButton(withTitle: L10n.text("action.cancel"))
        alert.window.initialFirstResponder = field
        guard alert.runModal() == .alertFirstButtonReturn else { return nil }
        return field.stringValue
    }
    static func goToFolder(_ tab: BrowserTab) {
        guard let path = text(title: L10n.text("path.go"), message: L10n.text("path.prompt"), value: tab.location.path, action: L10n.text("action.go")) else { return }
        let expanded = (path as NSString).expandingTildeInPath
        guard expanded.hasPrefix("/") else { tab.error = L10n.text("path.invalid"); return }
        tab.navigate(to: URL(fileURLWithPath: expanded))
    }
}

@MainActor
final class IconCache {
    static let shared = IconCache()
    private let cache = NSCache<NSString, NSImage>()
    init() { cache.countLimit = 1200 }
    func icon(_ url: URL) -> NSImage {
        let key = url.path as NSString
        if let image = cache.object(forKey: key) { return image }
        let image = NSWorkspace.shared.icon(forFile: url.path)
        cache.setObject(image, forKey: key)
        return image
    }
}
