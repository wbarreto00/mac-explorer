import SwiftUI
import AppKit
import ExplorerCore

@main
enum MacExplorerLauncher {
    static func main() {
        L10n.configureNativeLanguage()
        MacExplorerApp.main()
    }
}

struct MacExplorerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate
    var body: some Scene {
        WindowGroup("Mac Explorer") {
            ContentView()
                .frame(minWidth: 920, minHeight: 580)
        }
        .defaultSize(width: 1240, height: 780)
        .commands { ExplorerCommands() }
        Settings { AppSettingsView() }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        if MainActor.assumeIsolated({ Operations.shared.busy }) {
            let alert = NSAlert()
            alert.messageText = L10n.text("operation.busy")
            alert.informativeText = L10n.text("operation.wait")
            alert.runModal()
            return .terminateCancel
        }
        return .terminateNow
    }
}
