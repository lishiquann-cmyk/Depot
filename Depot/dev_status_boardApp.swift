import SwiftUI
import AppKit

@main
struct DepotApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var viewModel = AppViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(viewModel)
                .onAppear { appDelegate.viewModel = viewModel }
        }
        .defaultSize(width: 800, height: 600)
        .windowResizability(.contentMinSize)
    }
}

// MARK: - App Delegate

final class AppDelegate: NSObject, NSApplicationDelegate {
    var viewModel: AppViewModel? = nil

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        guard let vm = viewModel else { return .terminateNow }

        let count = vm.activeScriptCount
        vm.saveScriptStates()

        guard count > 0 else {
            vm.stopAllScripts()
            return .terminateNow
        }

        NSApp.activate(ignoringOtherApps: true)

        let alert = NSAlert()
        alert.messageText = "有 \(count) 个脚本正在运行"
        alert.informativeText = "退出将终止所有正在运行的进程，是否继续？"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "退出")
        alert.addButton(withTitle: "取消")
        alert.window.level = .floating

        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            vm.stopAllScripts()
            NSApp.reply(toApplicationShouldTerminate: true)
        } else {
            NSApp.reply(toApplicationShouldTerminate: false)
        }
        return .terminateLater
    }
}
