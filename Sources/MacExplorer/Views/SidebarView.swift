import SwiftUI
import ExplorerCore

struct SidebarView: View {
    @ObservedObject var tab: BrowserTab
    @ObservedObject var workspace: WorkspaceState
    @ObservedObject private var preferences = PreferencesStore.shared
    @State private var favoriteDropTargeted = false
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(L10n.text("sidebar.navigation")).font(.system(size: 10, weight: .semibold)).foregroundStyle(.secondary)
                Spacer()
                Button { preferences.toggleFavorite(tab.location) } label: { Image(systemName: preferences.isFavorite(tab.location) ? "star.fill" : "star") }.buttonStyle(.borderless).help(L10n.text("favorite.toggle"))
            }.padding(.horizontal, 16).padding(.top, 17).padding(.bottom, 10)
            Text(L10n.text("sidebar.favorites"))
                .font(.system(size: 11, weight: .semibold)).foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16).frame(height: 28)
                .background(favoriteDropTargeted ? Color.accentColor.opacity(0.2) : Color.clear)
                .contentShape(Rectangle())
                .help(L10n.text("favorite.drop_hint"))
                .onDrop(of: [.fileURL], isTargeted: $favoriteDropTargeted) { FavoriteDrop.accept($0) }
            FolderTree(tab: tab, workspace: workspace, favorites: preferences.favorites)
            HStack(spacing: 7) {
                Image(systemName: "internaldrive")
                Text("Apple Silicon · arm64").font(.system(size: 10))
            }.foregroundStyle(.tertiary).padding(14)
        }.background(.regularMaterial)
    }
}

private final class FolderNode: NSObject {
    let url: URL?
    let label: String
    var children: [FolderNode]?
    var loading = false
    var failed = false
    let symbolic: Bool
    init(url: URL, symbolic: Bool = false) {
        self.url = url; label = Display.folderName(url); self.symbolic = symbolic
    }
    init(header: String, children: [FolderNode]) {
        url = nil; label = header; self.children = children; symbolic = false
    }
}

private struct FolderTree: NSViewRepresentable {
    @ObservedObject var tab: BrowserTab
    var workspace: WorkspaceState
    var favorites: [URL]
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    func makeNSView(context: Context) -> NSScrollView {
        let tree = NSOutlineView()
        let column = NSTableColumn(identifier: .init("folders"))
        tree.addTableColumn(column); tree.outlineTableColumn = column
        tree.headerView = nil; tree.rowHeight = 28
        tree.style = .sourceList; tree.indentationPerLevel = 14
        tree.delegate = context.coordinator; tree.dataSource = context.coordinator
        tree.target = context.coordinator; tree.action = #selector(Coordinator.clicked)
        tree.backgroundColor = .clear
        tree.registerForDraggedTypes([.fileURL])
        tree.setDraggingSourceOperationMask(.copy, forLocal: true)
        tree.setDraggingSourceOperationMask(.copy, forLocal: false)
        let menu = NSMenu(); menu.delegate = context.coordinator; menu.autoenablesItems = false; tree.menu = menu
        let scroll = NSScrollView()
        scroll.drawsBackground = false; scroll.hasVerticalScroller = true; scroll.documentView = tree
        context.coordinator.tree = tree
        context.coordinator.buildRoots()
        tree.reloadData(); context.coordinator.roots.dropFirst().forEach { tree.expandItem($0) }
        return scroll
    }
    func updateNSView(_ view: NSScrollView, context: Context) {
        let old = context.coordinator.parent
        context.coordinator.parent = self
        if old.favorites != favorites || context.coordinator.lastHidden != tab.preferences.showHidden {
            context.coordinator.buildRoots(); context.coordinator.tree?.reloadData()
            context.coordinator.roots.dropFirst().forEach { context.coordinator.tree?.expandItem($0) }
        }
        context.coordinator.refreshCurrentNode()
        context.coordinator.highlight()
    }

    @MainActor final class Coordinator: NSObject, NSOutlineViewDataSource, NSOutlineViewDelegate, NSMenuDelegate {
        var parent: FolderTree
        weak var tree: NSOutlineView?
        var roots: [FolderNode] = []
        var lastHidden = false
        var lastFolderSignature = ""
        private var menuFolder: URL?
        private var displayedRoots: [FolderNode] { (roots.first?.children ?? []) + roots.dropFirst() }
        init(_ parent: FolderTree) { self.parent = parent }
        func buildRoots() {
            lastFolderSignature = ""
            lastHidden = parent.tab.preferences.showHidden
            let volumes = (FileManager.default.mountedVolumeURLs(includingResourceValuesForKeys: [.volumeIsBrowsableKey], options: [.skipHiddenVolumes]) ?? []).filter { $0.path != "/" }
            roots = [
                FolderNode(header: L10n.text("sidebar.favorites"), children: parent.favorites.map { FolderNode(url: $0) }),
                FolderNode(header: L10n.text("sidebar.mac"), children: [FolderNode(url: URL(fileURLWithPath: "/")), FolderNode(url: URL(fileURLWithPath: "/Applications"))])
            ]
            if !volumes.isEmpty { roots.append(FolderNode(header: L10n.text("sidebar.volumes"), children: volumes.map { FolderNode(url: $0) })) }
        }
        func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
            guard let node = item as? FolderNode else { return displayedRoots.count }
            if node.children == nil { load(node) }
            return node.children?.count ?? 0
        }
        func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
            if let node = item as? FolderNode { return node.children![index] }
            return displayedRoots[index]
        }
        func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
            guard let node = item as? FolderNode else { return false }
            return !node.symbolic && !node.failed && (node.children == nil || !(node.children?.isEmpty ?? true))
        }
        func outlineView(_ outlineView: NSOutlineView, isGroupItem item: Any) -> Bool { (item as? FolderNode)?.url == nil }
        func outlineView(_ outlineView: NSOutlineView, shouldSelectItem item: Any) -> Bool { (item as? FolderNode)?.url != nil }
        func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
            guard let node = item as? FolderNode else { return nil }
            let cell = NSTableCellView()
            let text = NSTextField(labelWithString: node.label)
            text.font = .systemFont(ofSize: node.url == nil ? 11 : 12, weight: node.url == nil ? .semibold : .regular)
            text.textColor = node.url == nil ? .secondaryLabelColor : .labelColor
            text.lineBreakMode = .byTruncatingMiddle
            text.translatesAutoresizingMaskIntoConstraints = false
            cell.addSubview(text); cell.textField = text
            if let url = node.url {
                let icon = NSImageView(image: IconCache.shared.icon(url))
                icon.translatesAutoresizingMaskIntoConstraints = false; cell.addSubview(icon)
                NSLayoutConstraint.activate([icon.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: 2), icon.centerYAnchor.constraint(equalTo: cell.centerYAnchor), icon.widthAnchor.constraint(equalToConstant: 18), icon.heightAnchor.constraint(equalToConstant: 18), text.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 7)])
                cell.toolTip = url.path
            } else {
                text.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: 2).isActive = true
            }
            NSLayoutConstraint.activate([text.centerYAnchor.constraint(equalTo: cell.centerYAnchor), text.trailingAnchor.constraint(equalTo: cell.trailingAnchor, constant: -4)])
            return cell
        }
        @objc func clicked() {
            guard let tree, tree.clickedRow >= 0, let node = tree.item(atRow: tree.clickedRow) as? FolderNode, let url = node.url else { return }
            parent.tab.navigate(to: url)
        }
        func outlineView(_ outlineView: NSOutlineView, pasteboardWriterForItem item: Any) -> NSPasteboardWriting? {
            (item as? FolderNode)?.url as NSURL?
        }
        private func isFavoritesTarget(_ item: Any?, info: NSDraggingInfo, in outline: NSOutlineView) -> Bool {
            guard let header = roots.first else { return false }
            var node = item as? FolderNode
            while let current = node {
                if current === header || header.children?.contains(where: { $0 === current }) == true { return true }
                node = outline.parent(forItem: current) as? FolderNode
            }
            // An insertion between root groups may be proposed with a nil item.
            guard item == nil else { return false }
            let point = outline.convert(info.draggingLocation, from: nil)
            let row = outline.row(at: point)
            let nextGroup = roots.count > 1 ? outline.row(forItem: roots[1]) : outline.numberOfRows
            return row >= 0 && row < nextGroup
        }
        private func droppedURLs(_ info: NSDraggingInfo) -> [URL] {
            (info.draggingPasteboard.readObjects(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true]) as? [URL]) ?? []
        }
        func outlineView(_ outlineView: NSOutlineView, validateDrop info: NSDraggingInfo, proposedItem item: Any?, proposedChildIndex index: Int) -> NSDragOperation {
            guard isFavoritesTarget(item, info: info, in: outlineView), !droppedURLs(info).isEmpty else { return [] }
            outlineView.setDropItem(nil, dropChildIndex: roots.first?.children?.count ?? 0)
            return .copy
        }
        func outlineView(_ outlineView: NSOutlineView, acceptDrop info: NSDraggingInfo, item: Any?, childIndex index: Int) -> Bool {
            guard isFavoritesTarget(item, info: info, in: outlineView) else { return false }
            let urls = droppedURLs(info)
            guard !urls.isEmpty else { return false }
            PreferencesStore.shared.addFavorites(urls)
            return true
        }
        func menuWillOpen(_ menu: NSMenu) {
            menu.removeAllItems()
            menuFolder = nil
            guard let tree, tree.clickedRow >= 0, let node = tree.item(atRow: tree.clickedRow) as? FolderNode, let url = node.url else { return }
            menuFolder = url
            let saved = PreferencesStore.shared.isFavorite(url)
            let action = NSMenuItem(title: L10n.text(saved ? "favorite.remove" : "favorite.add"), action: #selector(toggleMenuFavorite), keyEquivalent: "")
            action.target = self; menu.addItem(action)
        }
        @objc private func toggleMenuFavorite() {
            if let url = menuFolder { PreferencesStore.shared.toggleFavorite(url) }
        }
        func highlight() {
            guard let tree else { return }
            for row in 0..<tree.numberOfRows {
                if let node = tree.item(atRow: row) as? FolderNode, node.url == parent.tab.location {
                    tree.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false); return
                }
            }
            tree.deselectAll(nil)
        }
        func refreshCurrentNode() {
            guard !parent.tab.isLoading, parent.tab.error == nil, parent.tab.query.isEmpty else { return }
            let children = parent.tab.entries.filter(\.navigable).sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
            let signature = parent.tab.location.path + "|" + children.map { $0.url.path }.joined(separator: "|")
            guard signature != lastFolderSignature else { return }
            lastFolderSignature = signature
            func visit(_ nodes: [FolderNode]) {
                for node in nodes {
                    if node.url == parent.tab.location, !node.symbolic {
                        let existing = Dictionary((node.children ?? []).compactMap { child in child.url.map { ($0, child) } }, uniquingKeysWith: { first, _ in first })
                        node.children = children.map { existing[$0.url] ?? FolderNode(url: $0.url, symbolic: $0.isSymbolicLink) }
                        let expanded = tree?.isItemExpanded(node) ?? false
                        tree?.reloadItem(node, reloadChildren: true)
                        if expanded { tree?.expandItem(node) }
                    } else if let children = node.children { visit(children) }
                }
            }
            visit(roots)
        }
        private func load(_ node: FolderNode) {
            guard !node.loading, let url = node.url, !node.symbolic else { return }
            node.loading = true
            let hidden = parent.tab.preferences.showHidden
            Task {
                let result = await Task.detached { try? FileService.list(url, showHidden: hidden) }.value
                node.loading = false
                node.failed = result == nil
                node.children = result?.entries.filter(\.navigable).sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }.map { FolderNode(url: $0.url, symbolic: $0.isSymbolicLink) } ?? []
                let expanded = self.tree?.isItemExpanded(node) ?? false
                self.tree?.reloadItem(node, reloadChildren: true)
                if expanded { self.tree?.expandItem(node) }
                self.highlight()
            }
        }
    }
}
