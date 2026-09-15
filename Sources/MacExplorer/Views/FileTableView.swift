import SwiftUI
import ExplorerCore

struct FileTableView: NSViewRepresentable {
    @ObservedObject var tab: BrowserTab
    var workspace: WorkspaceState
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    func makeNSView(context: Context) -> NSScrollView {
        let table = ExplorerTable()
        table.style = .fullWidth
        table.usesAlternatingRowBackgroundColors = true
        table.allowsMultipleSelection = true
        table.allowsColumnReordering = true
        table.allowsColumnResizing = true
        table.columnAutoresizingStyle = .lastColumnOnlyAutoresizingStyle
        table.delegate = context.coordinator; table.dataSource = context.coordinator
        table.target = context.coordinator; table.doubleAction = #selector(Coordinator.openRow)
        table.keyHandler = { [weak coordinator = context.coordinator] event in coordinator?.handleKey(event) ?? false }
        table.registerForDraggedTypes([.fileURL])
        table.setDraggingSourceOperationMask(.copy, forLocal: false)
        table.setDraggingSourceOperationMask(.copy, forLocal: true)
        let menu = NSMenu(); menu.delegate = context.coordinator; table.menu = menu
        let scroll = NSScrollView()
        scroll.hasVerticalScroller = true; scroll.hasHorizontalScroller = true
        scroll.documentView = table
        context.coordinator.table = table
        context.coordinator.update()
        return scroll
    }
    func updateNSView(_ view: NSScrollView, context: Context) {
        context.coordinator.parent = self
        context.coordinator.update()
    }

    enum Row: Equatable {
        case group(String, Int)
        case file(FileEntry)
    }
    @MainActor final class Coordinator: NSObject, NSTableViewDataSource, NSTableViewDelegate, NSMenuDelegate {
        var parent: FileTableView
        weak var table: ExplorerTable?
        var rows: [Row] = []
        var applying = false
        var fields: [SortField] = []
        var collapsed: Set<String> = []
        var lastShowExtensions: Bool?
        init(_ parent: FileTableView) { self.parent = parent }
        func update() {
            guard let table else { return }
            applying = true
            defer { applying = false }
            let desired: [SortField] = parent.tab.preferences.view == .list ? [.name] : parent.tab.preferences.columns
            let columnsChanged = fields != desired
            if fields != desired {
                table.tableColumns.forEach { table.removeTableColumn($0) }
                for field in desired {
                    let column = NSTableColumn(identifier: .init(field.rawValue))
                    column.title = field.title
                    column.minWidth = field == .name ? 200 : 95
                    column.width = field == .name ? 330 : (field == .size ? 105 : 170)
                    let savedWidth = UserDefaults.standard.double(forKey: "columnWidth:\(parent.tab.location.path):\(field.rawValue)")
                    if savedWidth >= column.minWidth { column.width = savedWidth }
                    column.resizingMask = [.autoresizingMask, .userResizingMask]
                    column.sortDescriptorPrototype = NSSortDescriptor(key: field.rawValue, ascending: true)
                    table.addTableColumn(column)
                }
                fields = desired
            }
            let descriptors = [NSSortDescriptor(key: parent.tab.preferences.sort.rawValue, ascending: parent.tab.preferences.ascending)]
            if table.sortDescriptors != descriptors { table.sortDescriptors = descriptors }
            var nextRows: [Row] = []
            for group in parent.tab.groups {
                if !group.title.isEmpty { nextRows.append(.group(group.title, group.entries.count)) }
                if !collapsed.contains(group.title) { nextRows += group.entries.map { .file($0) } }
            }
            let reload = columnsChanged || rows != nextRows || lastShowExtensions != parent.tab.preferences.showExtensions
            rows = nextRows
            lastShowExtensions = parent.tab.preferences.showExtensions
            if reload { table.reloadData() }
            let indexes = IndexSet(rows.indices.filter { index in if case .file(let item) = rows[index] { return parent.tab.selection.contains(item.url) }; return false })
            if table.selectedRowIndexes != indexes { table.selectRowIndexes(indexes, byExtendingSelection: false) }
        }
        func numberOfRows(in tableView: NSTableView) -> Int { rows.count }
        func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
            if case .group = rows[row] { return 34 }; return 28
        }
        func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool { if case .file = rows[row] { return true }; return false }
        func tableView(_ tableView: NSTableView, isGroupRow row: Int) -> Bool { if case .group = rows[row] { return true }; return false }
        func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
            guard rows.indices.contains(row) else { return nil }
            let field = SortField(rawValue: tableColumn?.identifier.rawValue ?? "name") ?? .name
            switch rows[row] {
            case .group(let title, let count):
                let label = NSTextField(labelWithString: field == .name ? "\(collapsed.contains(title) ? "▸" : "▾")  \(title)  (\(count))" : "")
                label.font = .systemFont(ofSize: 12, weight: .semibold); label.textColor = .secondaryLabelColor
                return label
            case .file(let item):
                let identifier = NSUserInterfaceItemIdentifier(field == .name ? "nameCell" : "valueCell")
                let cell: NSTableCellView
                if let reused = tableView.makeView(withIdentifier: identifier, owner: nil) as? NSTableCellView { cell = reused }
                else {
                    cell = NSTableCellView(); cell.identifier = identifier
                    let text = NSTextField(labelWithString: "")
                    text.font = .systemFont(ofSize: 12); text.lineBreakMode = .byTruncatingMiddle
                    text.translatesAutoresizingMaskIntoConstraints = false
                    cell.addSubview(text); cell.textField = text
                    if field == .name {
                        let image = NSImageView(); image.translatesAutoresizingMaskIntoConstraints = false
                        cell.addSubview(image); cell.imageView = image
                        NSLayoutConstraint.activate([image.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: 5), image.centerYAnchor.constraint(equalTo: cell.centerYAnchor), image.widthAnchor.constraint(equalToConstant: 19), image.heightAnchor.constraint(equalToConstant: 19), text.leadingAnchor.constraint(equalTo: image.trailingAnchor, constant: 7)])
                    } else { text.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: 6).isActive = true }
                    NSLayoutConstraint.activate([text.centerYAnchor.constraint(equalTo: cell.centerYAnchor), text.trailingAnchor.constraint(equalTo: cell.trailingAnchor, constant: -8)])
                }
                cell.textField?.stringValue = Display.value(field, item: item, extensions: parent.tab.preferences.showExtensions)
                cell.textField?.textColor = field == .name ? .labelColor : .secondaryLabelColor
                cell.textField?.alignment = field == .size ? .right : .left
                cell.imageView?.image = IconCache.shared.icon(item.url)
                cell.alphaValue = item.isHidden ? 0.55 : 1
                cell.toolTip = item.url.path
                return cell
            }
        }
        func tableViewSelectionDidChange(_ notification: Notification) {
            guard !applying, let table else { return }
            let selection = Set(table.selectedRowIndexes.compactMap { index in if case .file(let item) = rows[index] { return item.url }; return nil })
            if parent.tab.selection != selection { parent.tab.selection = selection }
        }
        func tableView(_ tableView: NSTableView, sortDescriptorsDidChange oldDescriptors: [NSSortDescriptor]) {
            guard !applying, let sort = tableView.sortDescriptors.first, let field = SortField(rawValue: sort.key ?? "") else { return }
            var settings = parent.tab.preferences
            settings.sort = field; settings.ascending = sort.ascending
            parent.tab.preferences = settings
        }
        func tableViewColumnDidMove(_ notification: Notification) {
            guard !applying, parent.tab.preferences.view == .details, let table else { return }
            let order = table.tableColumns.compactMap { SortField(rawValue: $0.identifier.rawValue) }
            fields = order; parent.tab.preferences.columns = order
        }
        func tableViewColumnDidResize(_ notification: Notification) {
            guard !applying, let table else { return }
            for column in table.tableColumns {
                UserDefaults.standard.set(column.width, forKey: "columnWidth:\(parent.tab.location.path):\(column.identifier.rawValue)")
            }
        }
        @objc func openRow() {
            guard let table, rows.indices.contains(table.clickedRow) else { return }
            switch rows[table.clickedRow] {
            case .file(let entry): parent.tab.open(entry)
            case .group(let title, _):
                if collapsed.contains(title) { collapsed.remove(title) } else { collapsed.insert(title) }; update()
            }
        }
        func handleKey(_ event: NSEvent) -> Bool {
            let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            if flags.contains(.command) { return false }
            switch event.keyCode {
            case 36, 76: parent.tab.openSelection(); return true
            case 49: parent.tab.showInspector.toggle(); return true
            case 120: Operations.shared.rename(parent.tab); return true
            case 51: parent.tab.up(); return true
            default: return false
            }
        }
        func tableView(_ tableView: NSTableView, pasteboardWriterForRow row: Int) -> NSPasteboardWriting? {
            if case .file(let item) = rows[row] { return item.url as NSURL }; return nil
        }
        func tableView(_ tableView: NSTableView, validateDrop info: NSDraggingInfo, proposedRow row: Int, proposedDropOperation dropOperation: NSTableView.DropOperation) -> NSDragOperation {
            guard !Operations.shared.busy else { return [] }
            if rows.indices.contains(row), case .file(let item) = rows[row], item.navigable { tableView.setDropRow(row, dropOperation: .on) }
            else { tableView.setDropRow(-1, dropOperation: .on) }
            return .copy
        }
        func tableView(_ tableView: NSTableView, acceptDrop info: NSDraggingInfo, row: Int, dropOperation: NSTableView.DropOperation) -> Bool {
            let urls = info.draggingPasteboard.readObjects(forClasses: [NSURL.self]) as? [URL] ?? []
            var folder = parent.tab.location
            if rows.indices.contains(row), case .file(let item) = rows[row], item.navigable { folder = item.url }
            guard !urls.isEmpty else { return false }
            Operations.shared.transfer(urls, into: folder, moving: false, tab: parent.tab)
            return true
        }
        func menuWillOpen(_ menu: NSMenu) {
            guard let table else { return }
            if rows.indices.contains(table.clickedRow), case .file(let item) = rows[table.clickedRow], !parent.tab.selection.contains(item.url) {
                table.selectRowIndexes(IndexSet(integer: table.clickedRow), byExtendingSelection: false)
            } else if table.clickedRow < 0 { table.deselectAll(nil) }
            menu.removeAllItems()
            let selected = !parent.tab.selection.isEmpty, busy = Operations.shared.busy
            add(menu, L10n.text("action.open"), "open", selected)
            if parent.tab.selectedEntries.first?.navigable == true { add(menu, L10n.text("action.open_tab"), "tab", true) }
            let folders = parent.tab.selectedEntries.filter(\.navigable).map(\.url)
            if !folders.isEmpty {
                let allSaved = folders.allSatisfy { PreferencesStore.shared.isFavorite($0) }
                add(menu, L10n.text(allSaved ? "favorite.remove" : "favorite.add"), allSaved ? "removeFavorite" : "addFavorite", true)
            }
            add(menu, L10n.text("action.finder"), "finder", selected)
            menu.addItem(.separator())
            add(menu, L10n.text("action.cut"), "cut", selected); add(menu, L10n.text("action.copy"), "copy", selected)
            add(menu, L10n.text("action.paste_here"), "paste", !busy)
            add(menu, L10n.text("action.copy_to"), "copyTo", selected && !busy); add(menu, L10n.text("action.move_to"), "moveTo", selected && !busy)
            menu.addItem(.separator())
            add(menu, L10n.text("action.new_folder_menu"), "newFolder", !busy)
            add(menu, L10n.text("action.rename_menu"), "rename", parent.tab.selection.count == 1 && !busy)
            add(menu, L10n.text("action.tags"), "tags", selected && !busy)
            add(menu, L10n.text("action.trash_menu"), "trash", selected && !busy)
            menu.addItem(.separator())
            add(menu, L10n.text("action.copy_path"), "path", selected)
            add(menu, L10n.text("inspector.preview"), "properties", selected)
        }
        private func add(_ menu: NSMenu, _ title: String, _ action: String, _ enabled: Bool) {
            menu.autoenablesItems = false
            let item = NSMenuItem(title: title, action: #selector(performMenu(_:)), keyEquivalent: "")
            item.target = self; item.representedObject = action; item.isEnabled = enabled; menu.addItem(item)
        }
        @objc private func performMenu(_ item: NSMenuItem) {
            let tab = parent.tab, operations = Operations.shared
            switch item.representedObject as? String {
            case "open": tab.openSelection()
            case "tab": if let entry = tab.selectedEntries.first { parent.workspace.newTab(entry.url) }
            case "addFavorite": PreferencesStore.shared.addFavorites(tab.selectedEntries.filter(\.navigable).map(\.url))
            case "removeFavorite": PreferencesStore.shared.removeFavorites(tab.selectedEntries.filter(\.navigable).map(\.url))
            case "finder": NSWorkspace.shared.activateFileViewerSelecting(tab.selectedEntries.map(\.url))
            case "cut": operations.copy(tab, cut: true)
            case "copy": operations.copy(tab)
            case "paste": operations.paste(tab)
            case "copyTo": operations.chooseDestination(tab, moving: false)
            case "moveTo": operations.chooseDestination(tab, moving: true)
            case "newFolder": operations.newFolder(tab)
            case "rename": operations.rename(tab)
            case "tags": operations.editTags(tab)
            case "trash": operations.trash(tab)
            case "path": NSPasteboard.general.clearContents(); NSPasteboard.general.setString(tab.selectedEntries.map { $0.url.path }.joined(separator: "\n"), forType: .string)
            case "properties": tab.showInspector = true
            default: break
            }
        }
    }
}

final class ExplorerTable: NSTableView {
    var keyHandler: ((NSEvent) -> Bool)?
    override func keyDown(with event: NSEvent) {
        if keyHandler?(event) != true { super.keyDown(with: event) }
    }
}
