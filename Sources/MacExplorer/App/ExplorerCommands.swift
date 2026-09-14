import SwiftUI
import ExplorerCore

struct ExplorerCommands: Commands {
    @FocusedObject private var browser: BrowserTab?
    @FocusedObject private var workspace: WorkspaceState?
    @ObservedObject private var operations = Operations.shared
    var body: some Commands {
        CommandGroup(after: .newItem) {
            Button(L10n.text("action.new_tab")) { workspace?.newTab() }.keyboardShortcut("t")
            Button(L10n.text("action.close_tab")) { if let workspace { workspace.close(workspace.activeID) } }.keyboardShortcut("w", modifiers: [.command, .shift])
            Button(L10n.text("action.next_tab")) { workspace?.nextTab() }.keyboardShortcut(.tab, modifiers: .control)
            Divider()
            Button(L10n.text("action.new_folder")) { if let browser { operations.newFolder(browser) } }.keyboardShortcut("n", modifiers: [.command, .shift]).disabled(operations.busy)
            Button(L10n.text("action.rename_menu")) { if let browser { operations.rename(browser) } }.disabled(browser?.selection.count != 1 || operations.busy)
            Button(L10n.text("action.trash_menu")) { if let browser { operations.trash(browser) } }.keyboardShortcut(.delete, modifiers: .command).disabled(browser?.selection.isEmpty != false || operations.busy)
        }
        CommandGroup(replacing: .pasteboard) {
            Button(L10n.text("action.cut")) {
                if let editor = textEditor { editor.cut(nil) }
                else if let browser { operations.copy(browser, cut: true) }
            }.keyboardShortcut("x")
            Button(L10n.text("action.copy")) {
                if let editor = textEditor { editor.copy(nil) }
                else if let browser { operations.copy(browser) }
            }.keyboardShortcut("c")
            Button(L10n.text("action.paste")) {
                if let editor = textEditor { editor.paste(nil) }
                else if let browser { operations.paste(browser) }
            }.keyboardShortcut("v").disabled(operations.busy)
            Divider()
            Button(L10n.text("action.copy_to")) { if let browser { operations.chooseDestination(browser, moving: false) } }.disabled(browser?.selection.isEmpty != false || operations.busy)
            Button(L10n.text("action.move_to")) { if let browser { operations.chooseDestination(browser, moving: true) } }.disabled(browser?.selection.isEmpty != false || operations.busy)
            Button(L10n.text("selection.all")) {
                if let editor = textEditor { editor.selectAll(nil) }
                else if let browser { browser.selection = Set(browser.visibleEntries.map(\.url)) }
            }.keyboardShortcut("a")
        }
        CommandGroup(after: .undoRedo) {
            Button(L10n.text("action.undo_move")) { if let browser { operations.undo(browser) } }.keyboardShortcut("z", modifiers: [.command, .option]).disabled(!operations.canUndo)
        }
        CommandMenu(L10n.text("menu.navigate")) {
            Button(L10n.text("action.back")) { browser?.back() }.keyboardShortcut(.leftArrow, modifiers: .command).disabled(browser?.backStack.isEmpty != false)
            Button(L10n.text("action.forward")) { browser?.forward() }.keyboardShortcut(.rightArrow, modifiers: .command).disabled(browser?.forwardStack.isEmpty != false)
            Button(L10n.text("action.up")) { browser?.up() }.keyboardShortcut(.upArrow, modifiers: .command)
            Button(L10n.text("action.open_selection")) { browser?.openSelection() }.keyboardShortcut(.downArrow, modifiers: .command)
            Button(L10n.text("path.go_menu")) { if let browser { Dialogs.goToFolder(browser) } }.keyboardShortcut("l")
            Button(L10n.text("action.refresh")) { browser?.reload() }.keyboardShortcut("r")
        }
        CommandMenu(L10n.text("menu.organize")) {
            if let browser {
                OrganizationMenu(tab: browser)
                Divider()
                Button(L10n.text("action.show_hidden")) { browser.preferences.showHidden.toggle() }.keyboardShortcut(".", modifiers: [.command, .shift])
                Button(L10n.text("inspector.toggle")) { browser.showInspector.toggle() }.keyboardShortcut("i", modifiers: [.command, .option])
            }
        }
    }
    private var textEditor: NSTextView? { NSApp.keyWindow?.firstResponder as? NSTextView }
}
