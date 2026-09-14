import SwiftUI
import ExplorerCore

struct ContentView: View {
    @StateObject private var workspace = WorkspaceState()
    var body: some View {
        VStack(spacing: 0) {
            tabBar
            BrowserPane(tab: workspace.current, workspace: workspace).id(workspace.activeID)
        }
        .focusedSceneObject(workspace.current)
        .focusedSceneObject(workspace)
        .onReceive(NotificationCenter.default.publisher(for: .macExplorerFilesChanged)) { _ in workspace.tabs.forEach { $0.reload() } }
    }
    private var tabBar: some View {
        HStack(spacing: 4) {
            Image(systemName: "folder.badge.gearshape").foregroundStyle(.tint).font(.title3).padding(.horizontal, 10)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(workspace.tabs) { tab in TabButton(tab: tab, active: tab.id == workspace.activeID, select: { workspace.activeID = tab.id }, close: { workspace.close(tab.id) }, closable: workspace.tabs.count > 1) }
                }
            }
            Button { workspace.newTab() } label: { Image(systemName: "plus") }.help(L10n.text("help.new_tab")).buttonStyle(.borderless).padding(.horizontal, 12)
        }
        .padding(.vertical, 7)
        .background(.bar)
    }
}

private struct TabButton: View {
    @ObservedObject var tab: BrowserTab
    let active: Bool
    let select: () -> Void
    let close: () -> Void
    let closable: Bool
    var body: some View {
        HStack(spacing: 7) {
            Button(action: select) { Label(tab.title, systemImage: "folder").lineLimit(1).frame(minWidth: 80, maxWidth: 170, alignment: .leading) }.buttonStyle(.plain)
            if closable { Button(action: close) { Image(systemName: "xmark").font(.system(size: 9, weight: .semibold)) }.buttonStyle(.borderless).help(L10n.text("action.close_tab")) }
        }
        .padding(.horizontal, 12).padding(.vertical, 7)
        .background(active ? Color.accentColor.opacity(0.13) : Color.clear, in: RoundedRectangle(cornerRadius: 7))
        .overlay(alignment: .bottom) { if active { Capsule().fill(Color.accentColor).frame(height: 2).padding(.horizontal, 12) } }
        .help(tab.location.path)
    }
}

struct BrowserPane: View {
    @ObservedObject var tab: BrowserTab
    @ObservedObject var workspace: WorkspaceState
    @ObservedObject private var operations = Operations.shared
    @State private var address = ""
    @State private var editingAddress = false
    @FocusState private var addressFocus: Bool
    @FocusState private var searchFocus: Bool

    var body: some View {
        VStack(spacing: 0) {
            navigationBar
            Divider()
            actionBar
            Divider()
            HSplitView {
                SidebarView(tab: tab, workspace: workspace).frame(minWidth: 185, idealWidth: 220, maxWidth: 270)
                VStack(spacing: 0) {
                    if let error = tab.error { errorBanner(error) }
                    if !tab.query.isEmpty { searchScope }
                    if tab.isLoading && tab.entries.isEmpty {
                        Spacer(); ProgressView(L10n.text("folder.loading")); Spacer()
                    } else if tab.visibleEntries.isEmpty {
                        emptyState
                    } else if tab.preferences.view == .details || tab.preferences.view == .list {
                        FileTableView(tab: tab, workspace: workspace)
                    } else {
                        FileGridView(tab: tab, workspace: workspace)
                    }
                }
                .frame(minWidth: 400, maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(nsColor: .textBackgroundColor))
                if tab.showInspector { InspectorView(tab: tab).frame(minWidth: 230, idealWidth: 270, maxWidth: 360) }
            }
            Divider()
            statusBar
        }
        .onAppear { address = tab.location.path }
        .onChange(of: tab.location) { _, value in address = value.path; editingAddress = false }
        .background {
            Button("") { searchFocus = true }.keyboardShortcut("f").hidden()
        }
    }

    private var navigationBar: some View {
        HStack(spacing: 10) {
            navButton("chevron.left", L10n.text("help.back"), action: tab.back).disabled(tab.backStack.isEmpty)
            navButton("chevron.right", L10n.text("help.forward"), action: tab.forward).disabled(tab.forwardStack.isEmpty)
            navButton("arrow.up", L10n.text("help.up"), action: tab.up).disabled(tab.location.path == "/")
            navButton("arrow.clockwise", L10n.text("help.refresh"), action: tab.reload)
            HStack(spacing: 3) {
                Image(systemName: "folder").foregroundStyle(.secondary).padding(.leading, 8)
                if editingAddress {
                    TextField(L10n.text("path.placeholder"), text: $address).textFieldStyle(.plain).focused($addressFocus)
                        .onSubmit { navigateAddress() }
                        .onExitCommand { editingAddress = false; address = tab.location.path }
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 2) {
                            ForEach(breadcrumbs, id: \.self) { url in
                                if url.path != "/" { Image(systemName: "chevron.right").font(.system(size: 8)).foregroundStyle(.tertiary) }
                                Button(Display.folderName(url)) { tab.navigate(to: url) }.buttonStyle(.plain).lineLimit(1).padding(.horizontal, 4)
                            }
                        }.font(.system(size: 12))
                    }
                }
                Button { address = tab.location.path; editingAddress = true; addressFocus = true } label: { Image(systemName: "pencil").font(.system(size: 11)) }.buttonStyle(.borderless).help(L10n.text("help.edit_path")).padding(.horizontal, 7)
            }
            .frame(height: 30).background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 6))
            HStack(spacing: 5) {
                Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                TextField(L10n.text("search.placeholder"), text: $tab.query).textFieldStyle(.plain).focused($searchFocus)
                if !tab.query.isEmpty { Button { tab.query = "" } label: { Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary) }.buttonStyle(.plain) }
            }.padding(.horizontal, 8).frame(width: 220, height: 30).background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 6))
        }.padding(.horizontal, 14).padding(.vertical, 10)
    }
    private var actionBar: some View {
        HStack(spacing: 16) {
            Button { operations.newFolder(tab) } label: { Label(L10n.text("action.new_folder"), systemImage: "folder.badge.plus") }.disabled(operations.busy)
            Divider().frame(height: 19)
            actionIcon("scissors", L10n.text("help.cut"), enabled: !tab.selection.isEmpty) { operations.copy(tab, cut: true) }
            actionIcon("doc.on.doc", L10n.text("help.copy"), enabled: !tab.selection.isEmpty) { operations.copy(tab) }
            actionIcon("doc.on.clipboard", L10n.text("help.paste"), enabled: !operations.busy) { operations.paste(tab) }
            actionIcon("character.cursor.ibeam", L10n.text("help.rename"), enabled: tab.selection.count == 1 && !operations.busy) { operations.rename(tab) }
            actionIcon("trash", L10n.text("help.trash"), enabled: !tab.selection.isEmpty && !operations.busy) { operations.trash(tab) }
            Divider().frame(height: 19)
            Menu { OrganizationMenu(tab: tab) } label: { Label(L10n.text("menu.organize"), systemImage: "arrow.up.arrow.down") }.menuStyle(.borderlessButton).fixedSize()
            Menu { ViewOptionsMenu(tab: tab) } label: { Label(L10n.text("menu.view"), systemImage: tab.preferences.view.symbol) }.menuStyle(.borderlessButton).fixedSize()
            Spacer(minLength: 0)
            if operations.canUndo { actionIcon("arrow.uturn.backward", L10n.text("action.undo_move"), enabled: true) { operations.undo(tab) } }
            Button { tab.showInspector.toggle() } label: { Image(systemName: "sidebar.right") }.help(L10n.text("inspector.preview")).foregroundStyle(tab.showInspector ? Color.accentColor : Color.primary)
        }
        .buttonStyle(.borderless).font(.system(size: 12)).padding(.horizontal, 18).frame(height: 43)
    }
    private var searchScope: some View {
        HStack {
            Text(L10n.text("search.in")).foregroundStyle(.secondary)
            Picker(L10n.text("search.scope"), selection: $tab.recursiveSearch) {
                Text(L10n.text("search.current")).tag(false)
                Text(L10n.text("search.recursive")).tag(true)
            }.pickerStyle(.segmented).frame(width: 255)
            Spacer()
            if tab.isLoading { ProgressView().controlSize(.small) }
        }.font(.caption).padding(10).background(.bar)
    }
    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: tab.error == nil ? (tab.query.isEmpty ? "folder" : "magnifyingglass") : "folder.badge.questionmark").font(.system(size: 44, weight: .ultraLight)).foregroundStyle(.secondary)
            Text(tab.error == nil ? (tab.query.isEmpty ? L10n.text("folder.empty") : L10n.text("search.empty")) : L10n.text("folder.unavailable")).font(.title3)
            Text(tab.error == nil ? (tab.query.isEmpty ? L10n.text("folder.empty_hint") : L10n.text("search.empty_hint")) : L10n.text("folder.permission_hint")).foregroundStyle(.secondary).font(.callout)
            if tab.error == nil && tab.query.isEmpty { Button(L10n.text("action.new_folder")) { operations.newFolder(tab) } }
            Spacer()
        }.frame(maxWidth: .infinity).contextMenu { FileContextMenu(tab: tab) }
            .onDrop(of: [.fileURL], isTargeted: nil) { DropFiles.accept($0, folder: tab.location, tab: tab) }
    }
    private var statusBar: some View {
        HStack(spacing: 14) {
            if tab.isLoading || operations.busy { ProgressView().controlSize(.mini) }
            Text(L10n.count("count.items", tab.visibleEntries.count))
            if !tab.selection.isEmpty {
                Divider().frame(height: 12)
                Text(L10n.count("count.selected", tab.selection.count))
                let bytes = tab.selectedEntries.filter { !$0.navigable }.reduce(Int64(0)) { $0 + $1.size }
                if bytes > 0 { Text(ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)) }
            }
            Spacer()
            Text(tab.note.isEmpty ? operations.status : tab.note).lineLimit(1).help(tab.note.isEmpty ? operations.status : tab.note)
            Text("\(tab.preferences.group == .none ? "" : tab.preferences.group.title + " · ")\(tab.preferences.view.title)").foregroundStyle(.tertiary)
        }.font(.system(size: 11)).foregroundStyle(.secondary).padding(.horizontal, 16).frame(height: 29).background(.bar)
    }
    private func errorBanner(_ message: String) -> some View {
        HStack(alignment: .top) {
            Image(systemName: "exclamationmark.triangle").foregroundStyle(.orange)
            Text(message).font(.callout).textSelection(.enabled)
            Spacer()
            Button { tab.error = nil } label: { Image(systemName: "xmark") }.buttonStyle(.plain)
        }.padding(12).frame(maxWidth: .infinity, alignment: .leading).background(Color.orange.opacity(0.09))
    }
    private func navButton(_ symbol: String, _ help: String, action: @escaping () -> Void) -> some View {
        Button(action: action) { Image(systemName: symbol).frame(width: 18) }.buttonStyle(.borderless).help(help)
    }
    private func actionIcon(_ symbol: String, _ help: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) { Image(systemName: symbol).frame(width: 16) }.help(help).disabled(!enabled)
    }
    private var breadcrumbs: [URL] {
        var urls = [URL(fileURLWithPath: "/")]
        for component in tab.location.pathComponents.dropFirst() { urls.append(urls.last!.appendingPathComponent(component)) }
        return urls
    }
    private func navigateAddress() {
        let path = (address as NSString).expandingTildeInPath
        guard path.hasPrefix("/") else { tab.error = L10n.text("path.absolute"); return }
        tab.navigate(to: URL(fileURLWithPath: path)); editingAddress = false
    }
}
