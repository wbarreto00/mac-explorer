import AppKit
import ExplorerCore

@MainActor
final class Operations: ObservableObject {
    static let shared = Operations()
    @Published var busy = false
    @Published var status = ""
    @Published var undoMoves: [CompletedMove] = []
    private var cutURLs: [URL] = []
    private var cutChangeCount = -1
    private var editingTags = false
    var canPaste: Bool { !busy && !(NSPasteboard.general.readObjects(forClasses: [NSURL.self]) ?? []).isEmpty }
    var canUndo: Bool { !busy && !undoMoves.isEmpty }

    func copy(_ tab: BrowserTab, cut: Bool = false) {
        let urls = tab.selectedEntries.map(\.url)
        guard !urls.isEmpty else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.writeObjects(urls as [NSURL])
        cutURLs = cut ? urls : []
        cutChangeCount = NSPasteboard.general.changeCount
        status = L10n.count(cut ? "count.cut" : "count.copied", urls.count)
    }
    func paste(_ tab: BrowserTab) {
        let urls = (NSPasteboard.general.readObjects(forClasses: [NSURL.self]) as? [URL] ?? []).filter(\.isFileURL)
        let moving = !cutURLs.isEmpty && cutChangeCount == NSPasteboard.general.changeCount && Set(urls) == Set(cutURLs)
        transfer(urls, into: tab.location, moving: moving, tab: tab)
    }
    func transfer(_ urls: [URL], into folder: URL, moving: Bool, tab: BrowserTab) {
        guard !busy, !urls.isEmpty else { return }
        busy = true; status = moving ? L10n.text("operation.moving") : L10n.text("operation.copying")
        undoMoves = []
        Task {
            let result = await Task.detached(priority: .userInitiated) { () -> ([URL], [CompletedMove], [String]) in
                var targets: [URL] = [], moves: [CompletedMove] = [], errors: [String] = []
                // Ignore descendants when their ancestor is also in the selection.
                let roots = urls.filter { candidate in !urls.contains { other in other != candidate && candidate.path.hasPrefix(other.path + "/") } }
                for source in roots {
                    do {
                        let target = try FileActions.transfer(source: source, folder: folder, moving: moving)
                        targets.append(target)
                        if moving { moves.append(CompletedMove(original: source, current: target)) }
                    } catch { errors.append("\(source.lastPathComponent): \(error.localizedDescription)") }
                }
                return (targets, moves, errors)
            }.value
            self.undoMoves = result.1
            if moving {
                let succeeded = Set(result.1.map(\.original))
                self.cutURLs.removeAll { succeeded.contains($0) }
                if self.cutChangeCount == NSPasteboard.general.changeCount {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.writeObjects(self.cutURLs as [NSURL])
                    self.cutChangeCount = NSPasteboard.general.changeCount
                }
            }
            self.finish(tab, count: result.0.count, errors: result.2)
        }
    }
    func newFolder(_ tab: BrowserTab) {
        guard !busy, let name = Dialogs.text(title: L10n.text("action.new_folder"), message: L10n.format("folder.create_in", tab.location.path), value: L10n.text("action.new_folder"), action: L10n.text("action.create")) else { return }
        do {
            let url = try FileActions.newFolder(in: tab.location, name: name)
            status = L10n.format("folder.created", url.lastPathComponent); tab.reload()
        } catch { tab.error = error.localizedDescription }
    }
    func rename(_ tab: BrowserTab) {
        guard !busy, let item = tab.selectedEntries.first, tab.selection.count == 1,
              let name = Dialogs.text(title: L10n.text("action.rename"), message: L10n.text("rename.hint"), value: item.name, action: L10n.text("action.rename")) else { return }
        do {
            let move = try FileActions.rename(item.url, to: name)
            undoMoves = move.original == move.current ? [] : [move]
            status = L10n.text("operation.renamed"); tab.reload()
        } catch { tab.error = error.localizedDescription }
    }
    func chooseDestination(_ tab: BrowserTab, moving: Bool) {
        guard !busy, !tab.selection.isEmpty else { return }
        let urls = tab.selectedEntries.map(\.url)
        let panel = NSOpenPanel()
        panel.canChooseFiles = false; panel.canChooseDirectories = true; panel.allowsMultipleSelection = false
        panel.prompt = moving ? L10n.text("action.move_here") : L10n.text("action.copy_here")
        panel.message = L10n.text("operation.collision_hint")
        panel.directoryURL = tab.location
        if panel.runModal() == .OK, let destination = panel.url { transfer(urls, into: destination, moving: moving, tab: tab) }
    }
    func trash(_ tab: BrowserTab) {
        let urls = tab.selectedEntries.map(\.url)
        guard !busy, !urls.isEmpty else { return }
        let alert = NSAlert()
        alert.messageText = L10n.count("count.trash", urls.count)
        alert.informativeText = L10n.text("trash.hint")
        alert.addButton(withTitle: L10n.text("action.trash")); alert.addButton(withTitle: L10n.text("action.cancel"))
        guard alert.runModal() == .alertFirstButtonReturn else { return }
        busy = true; status = L10n.text("operation.trashing"); undoMoves = []
        Task {
            let result = await Task.detached { () -> ([CompletedMove], [String]) in
                var moves: [CompletedMove] = [], errors: [String] = []
                let roots = urls.filter { candidate in !urls.contains { $0 != candidate && candidate.path.hasPrefix($0.path + "/") } }
                for url in roots {
                    do { moves.append(try FileActions.trash(url)) }
                    catch { errors.append("\(url.lastPathComponent): \(error.localizedDescription)") }
                }
                return (moves, errors)
            }.value
            self.undoMoves = result.0
            self.finish(tab, count: result.0.count, errors: result.1)
        }
    }
    func undo(_ tab: BrowserTab) {
        guard canUndo else { return }
        let moves = undoMoves
        busy = true; status = L10n.text("operation.undoing")
        Task {
            let result = await Task.detached { () -> ([CompletedMove], [String]) in
                var pending: [CompletedMove] = [], errors: [String] = []
                for move in moves.reversed() {
                    do { try FileActions.restore(move) }
                    catch { pending.append(move); errors.append("\(move.original.lastPathComponent): \(error.localizedDescription)") }
                }
                return (pending, errors)
            }.value
            self.undoMoves = result.0
            self.finish(tab, count: moves.count - result.0.count, errors: result.1)
        }
    }
    func editTags(_ tab: BrowserTab) {
        let items = tab.selectedEntries
        guard !busy, !editingTags, !items.isEmpty else { return }
        editingTags = true
        Task {
            defer { editingTags = false }
            var initial = ""
            if items.count == 1 {
                status = L10n.text("tags.loading")
                let current = await Task.detached(priority: .utility) {
                    try? (items[0].url.resourceValues(forKeys: [.tagNamesKey]).tagNames ?? [])
                }.value
                guard let current else { status = L10n.text("tags.read_error"); return }
                initial = current.joined(separator: ", ")
            }
            guard !busy else { return }
            status = ""
            guard let raw = Dialogs.text(title: L10n.text("field.tags"), message: L10n.format("tags.prompt", Int64(items.count)), value: initial, action: L10n.text("action.apply")) else { return }
            let tags = Array(Set(raw.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty })).sorted()
            busy = true
            let errors = await Task.detached { () -> [String] in
                var errors: [String] = []
                for item in items {
                    do { try (item.url as NSURL).setResourceValue(tags, forKey: .tagNamesKey) }
                    catch { errors.append(error.localizedDescription) }
                }
                return errors
            }.value
            finish(tab, count: items.count - errors.count, errors: errors)
        }
    }
    func finish(_ tab: BrowserTab, count: Int, errors: [String]) {
        busy = false
        status = L10n.count("count.processed", count) + (errors.isEmpty ? "" : " " + L10n.count("count.failed", errors.count))
        tab.reload()
        NotificationCenter.default.post(name: .macExplorerFilesChanged, object: nil)
        if !errors.isEmpty {
            let alert = NSAlert()
            alert.messageText = L10n.text("operation.some_failed")
            alert.informativeText = errors.prefix(8).joined(separator: "\n")
            alert.runModal()
        }
    }
}

extension Notification.Name { static let macExplorerFilesChanged = Notification.Name("MacExplorerFilesChanged") }
