import SwiftUI
import ExplorerCore

struct OrganizationMenu: View {
    @ObservedObject var tab: BrowserTab
    var body: some View {
        Menu(L10n.text("sort.by")) {
            Picker(L10n.text("sort.field"), selection: $tab.preferences.sort) { ForEach(SortField.allCases, id: \.self) { Text($0.title).tag($0) } }.pickerStyle(.inline)
            Divider()
            Toggle(L10n.text("sort.ascending"), isOn: $tab.preferences.ascending)
            Toggle(L10n.text("sort.folders_first"), isOn: $tab.preferences.foldersFirst)
        }
        Menu(L10n.text("group.by")) {
            Picker(L10n.text("group.field"), selection: $tab.preferences.group) { ForEach(GroupField.allCases, id: \.self) { Text($0.title).tag($0) } }.pickerStyle(.inline)
            Divider()
            Toggle(L10n.text("group.ascending"), isOn: $tab.preferences.groupsAscending)
        }
    }
}

struct ViewOptionsMenu: View {
    @ObservedObject var tab: BrowserTab
    var body: some View {
        Picker(L10n.text("view.mode"), selection: $tab.preferences.view) {
            ForEach(ViewMode.allCases, id: \.self) { mode in Label(mode.title, systemImage: mode.symbol).tag(mode) }
        }.pickerStyle(.inline)
        Divider()
        Menu(L10n.text("view.columns")) {
            ForEach(SortField.allCases.filter { $0 != .name }, id: \.self) { field in
                Toggle(field.title, isOn: Binding(get: { tab.preferences.columns.contains(field) }, set: { show in
                    if show { tab.preferences.columns.append(field) }
                    else { tab.preferences.columns.removeAll { $0 == field } }
                }))
            }
        }
        Toggle(L10n.text("view.extensions"), isOn: $tab.preferences.showExtensions)
        Toggle(L10n.text("hidden.files"), isOn: $tab.preferences.showHidden)
        Toggle(L10n.text("inspector.toggle"), isOn: $tab.showInspector)
        Divider()
        Button(L10n.text("view.save_default")) { PreferencesStore.shared.useAsDefault(tab.preferences) }
    }
}

struct FileContextMenu: View {
    @ObservedObject var tab: BrowserTab
    @ObservedObject private var operations = Operations.shared
    var openInTab: ((URL) -> Void)?
    var body: some View {
        Button(L10n.text("action.open")) { tab.openSelection() }.disabled(tab.selection.isEmpty)
        if let entry = tab.selectedEntries.first, entry.navigable, let openInTab {
            Button(L10n.text("action.open_tab")) { openInTab(entry.url) }
        }
        Button(L10n.text("action.finder")) { NSWorkspace.shared.activateFileViewerSelecting(tab.selectedEntries.map(\.url)) }.disabled(tab.selection.isEmpty)
        Divider()
        Button(L10n.text("action.cut")) { operations.copy(tab, cut: true) }.disabled(tab.selection.isEmpty)
        Button(L10n.text("action.copy")) { operations.copy(tab) }.disabled(tab.selection.isEmpty)
        Button(L10n.text("action.paste_here")) { operations.paste(tab) }.disabled(operations.busy)
        Button(L10n.text("action.copy_to")) { operations.chooseDestination(tab, moving: false) }.disabled(tab.selection.isEmpty || operations.busy)
        Button(L10n.text("action.move_to")) { operations.chooseDestination(tab, moving: true) }.disabled(tab.selection.isEmpty || operations.busy)
        Divider()
        Button(L10n.text("action.new_folder_menu")) { operations.newFolder(tab) }.disabled(operations.busy)
        Button(L10n.text("action.rename_menu")) { operations.rename(tab) }.disabled(tab.selection.count != 1 || operations.busy)
        Button(L10n.text("action.tags")) { operations.editTags(tab) }.disabled(tab.selection.isEmpty || operations.busy)
        Button(L10n.text("action.trash_menu")) { operations.trash(tab) }.disabled(tab.selection.isEmpty || operations.busy)
        Divider()
        Button(L10n.text("action.copy_path")) {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(tab.selectedEntries.map { $0.url.path }.joined(separator: "\n"), forType: .string)
        }.disabled(tab.selection.isEmpty)
        Button(L10n.text("inspector.preview")) { tab.showInspector = true }.disabled(tab.selection.isEmpty)
    }
}
