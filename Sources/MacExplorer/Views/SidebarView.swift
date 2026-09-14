import SwiftUI
import ExplorerCore

struct SidebarView: View {
    @ObservedObject var tab: BrowserTab
    @ObservedObject var workspace: WorkspaceState
    @ObservedObject private var preferences = PreferencesStore.shared
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(L10n.text("sidebar.navigation")).font(.system(size: 10, weight: .semibold)).foregroundStyle(.secondary)
                Spacer()
                Button { preferences.toggleFavorite(tab.location) } label: { Image(systemName: preferences.favorites.contains(tab.location) ? "star.fill" : "star") }.buttonStyle(.borderless).help(L10n.text("favorite.toggle"))
            }.padding(.horizontal, 16).padding(.top, 17).padding(.bottom, 10)
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
        let scroll = NSScrollView()
        scroll.drawsBackground = false; scroll.hasVerticalScroller = true; scroll.documentView = tree
        context.coordinator.tree = tree
        context.coordinator.buildRoots()
        tree.reloadData(); context.coordinator.roots.forEach { tree.expandItem($0) }
        return scroll
    }
    func updateNSView(_ view: NSScrollView, context: Context) {
        let old = context.coordinator.parent
        context.coordinator.parent = self
        if old.favorites != favorites || context.coordinator.lastHidden != tab.preferences.showHidden {
            context.coordinator.buildRoots(); context.coordinator.tree?.reloadData()
            context.coordinator.roots.forEach { context.coordinator.tree?.expandItem($0) }
        }
        context.coordinator.refreshCurrentNode()
        context.coordinator.highlight()
    }

    @MainActor final class Coordinator: NSObject, NSOutlineViewDataSource, NSOutlineViewDelegate {
        var parent: FolderTree
        weak var tree: NSOutlineView?
        var roots: [FolderNode] = []
        var lastHidden = false
        var lastFolderSignature = ""
        init(_ parent: FolderTree) { self.parent = parent }
        func buildRoots() {
            lastHidden = parent.tab.preferences.showHidden
            let volumes = (FileManager.default.mountedVolumeURLs(includingResourceValuesForKeys: [.volumeIsBrowsableKey], options: [.skipHiddenVolumes]) ?? []).filter { $0.path != "/" }
            roots = [
                FolderNode(header: L10n.text("sidebar.favorites"), children: parent.favorites.map { FolderNode(url: $0) }),
                FolderNode(header: L10n.text("sidebar.mac"), children: [FolderNode(url: URL(fileURLWithPath: "/")), FolderNode(url: URL(fileURLWithPath: "/Applications"))])
            ]
            if !volumes.isEmpty { roots.append(FolderNode(header: L10n.text("sidebar.volumes"), children: volumes.map { FolderNode(url: $0) })) }
        }
        func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
            guard let node = item as? FolderNode else { return roots.count }
            if node.children == nil { load(node) }
            return node.children?.count ?? 0
        }
        func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
            if let node = item as? FolderNode { return node.children![index] }
            return roots[index]
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
            } else { text.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: 2).isActive = true }
            NSLayoutConstraint.activate([text.centerYAnchor.constraint(equalTo: cell.centerYAnchor), text.trailingAnchor.constraint(equalTo: cell.trailingAnchor, constant: -4)])
            return cell
        }
        @objc func clicked() {
            guard let tree, tree.clickedRow >= 0, let node = tree.item(atRow: tree.clickedRow) as? FolderNode, let url = node.url else { return }
            parent.tab.navigate(to: url)
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
