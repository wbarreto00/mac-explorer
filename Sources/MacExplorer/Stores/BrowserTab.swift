import AppKit
import Combine
import ExplorerCore

@MainActor
final class BrowserTab: ObservableObject, Identifiable {
    let id = UUID()
    @Published var location: URL
    @Published var entries: [FileEntry] = []
    @Published var selection: Set<URL> = []
    @Published var preferences: FolderPreferences {
        didSet {
            if !changingLocation { PreferencesStore.shared.save(preferences, for: location) }
            if oldValue.showHidden != preferences.showHidden || Self.requiresTags(oldValue) != Self.requiresTags(preferences) { reload() }
            else { rebuild() }
        }
    }
    @Published var query = "" { didSet { scheduleLoad() } }
    @Published var recursiveSearch = false { didSet { reload() } }
    @Published var groups: [FileGroup] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var note = ""
    @Published var showInspector = false
    @Published var backStack: [URL] = []
    @Published var forwardStack: [URL] = []
    private var changingLocation = false
    private var task: Task<Void, Never>?
    private var loadID = UUID()
    private let watcher = DirectoryWatcher()
    private var debounce: DispatchWorkItem?
    private var searchDebounce: DispatchWorkItem?

    init(url: URL) {
        location = url.standardizedFileURL
        preferences = PreferencesStore.shared.settings(for: url)
        reload()
        watch()
    }

    var title: String { Display.folderName(location) }
    var visibleEntries: [FileEntry] { groups.flatMap(\.entries) }
    var selectedEntries: [FileEntry] { visibleEntries.filter { selection.contains($0.url) } }
    private static func requiresTags(_ preferences: FolderPreferences) -> Bool {
        preferences.sort == .tags || preferences.group == .tags || (preferences.view == .details && preferences.columns.contains(.tags))
    }

    func navigate(to url: URL, record: Bool = true) {
        let target = url.standardizedFileURL
        guard target != location else { return }
        if record { backStack.append(location); forwardStack.removeAll() }
        changingLocation = true
        location = target
        query = ""
        selection.removeAll()
        entries = []
        preferences = PreferencesStore.shared.settings(for: target)
        changingLocation = false
        reload()
        watch()
    }
    func back() {
        guard let target = backStack.popLast() else { return }
        forwardStack.append(location)
        navigate(to: target, record: false)
    }
    func forward() {
        guard let target = forwardStack.popLast() else { return }
        backStack.append(location)
        navigate(to: target, record: false)
    }
    func up() { navigate(to: location.deletingLastPathComponent()) }
    func open(_ entry: FileEntry) {
        if entry.navigable { navigate(to: entry.url) }
        else if !NSWorkspace.shared.open(entry.url) { error = L10n.text("error.no_app") }
    }
    func openSelection() { if let entry = selectedEntries.first { open(entry) } }

    private func watch() {
        watcher.watch(location) { [weak self] in
            guard let self else { return }
            self.debounce?.cancel()
            let item = DispatchWorkItem { [weak self] in self?.reload() }
            self.debounce = item
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35, execute: item)
        }
    }
    private func scheduleLoad() {
        searchDebounce?.cancel()
        let work = DispatchWorkItem { [weak self] in self?.reload() }
        searchDebounce = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25, execute: work)
    }

    func reload() {
        task?.cancel()
        let identifier = UUID()
        loadID = identifier
        let folder = location, hidden = preferences.showHidden, text = query, recursive = recursiveSearch
        let includeTags = Self.requiresTags(preferences)
        isLoading = true
        error = nil
        note = ""
        task = Task { [weak self] in
            let worker = Task.detached(priority: .userInitiated) { () throws -> DirectoryResult in
                if recursive && !text.isEmpty {
                    return try FileService.search(folder, query: text, showHidden: hidden, includeTags: includeTags, cancelled: { Task.isCancelled })
                }
                return try FileService.list(folder, showHidden: hidden, includeTags: includeTags)
            }
            do {
                let result = try await withTaskCancellationHandler(operation: { try await worker.value }, onCancel: { worker.cancel() })
                guard let self, !Task.isCancelled, self.loadID == identifier else { return }
                self.entries = result.entries
                self.rebuild()
                self.selection.formIntersection(Set(self.visibleEntries.map(\.url)))
                if result.skipped > 0 { self.note = L10n.count("count.unreadable", result.skipped) }
                if result.limited { self.note += L10n.text("search.limited") }
                self.isLoading = false
            } catch {
                guard let self, !Task.isCancelled, self.loadID == identifier else { return }
                self.entries = []
                self.groups = []
                self.error = L10n.format("folder.read_error", folder.path, error.localizedDescription)
                self.isLoading = false
            }
        }
    }
    func rebuild() {
        let filtered = query.isEmpty || recursiveSearch ? entries : entries.filter { $0.name.localizedStandardContains(query) }
        groups = Organization.groups(filtered, preferences: preferences)
    }
    deinit { task?.cancel(); debounce?.cancel(); searchDebounce?.cancel() }
    func select(_ entry: FileEntry, modifiers: NSEvent.ModifierFlags = NSEvent.modifierFlags) {
        if modifiers.contains(.command) {
            if selection.contains(entry.url) { selection.remove(entry.url) } else { selection.insert(entry.url) }
        } else if modifiers.contains(.shift), let anchor = visibleEntries.firstIndex(where: { selection.contains($0.url) }), let index = visibleEntries.firstIndex(of: entry) {
            selection.formUnion(visibleEntries[min(anchor, index)...max(anchor, index)].map(\.url))
        } else { selection = [entry.url] }
    }
}

@MainActor
final class WorkspaceState: ObservableObject {
    @Published var tabs: [BrowserTab]
    @Published var activeID: UUID
    init() {
        let args = ProcessInfo.processInfo.arguments
        let url: URL
        if let index = args.firstIndex(of: "--folder"), args.indices.contains(index + 1) { url = URL(fileURLWithPath: args[index + 1]) }
        else { url = FileManager.default.homeDirectoryForCurrentUser }
        let tab = BrowserTab(url: url)
        tabs = [tab]; activeID = tab.id
    }
    var current: BrowserTab { tabs.first { $0.id == activeID } ?? tabs[0] }
    func newTab(_ url: URL? = nil) {
        let tab = BrowserTab(url: url ?? current.location)
        tabs.append(tab); activeID = tab.id
    }
    func close(_ id: UUID) {
        guard tabs.count > 1, let index = tabs.firstIndex(where: { $0.id == id }) else { return }
        tabs.remove(at: index)
        if activeID == id { activeID = tabs[min(index, tabs.count - 1)].id }
    }
    func nextTab() {
        guard let index = tabs.firstIndex(where: { $0.id == activeID }) else { return }
        activeID = tabs[(index + 1) % tabs.count].id
    }
}
