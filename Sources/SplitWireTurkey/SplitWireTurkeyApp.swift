import SwiftUI

@main
struct SplitWireTurkeyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .frame(minWidth: 800, minHeight: 600)
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("SplitWire-Turkey Hakkında") {
                    NSApplication.shared.orderFrontStandardAboutPanel(
                        options: [
                            NSApplication.AboutPanelOptionKey.applicationName: "SplitWire-Turkey",
                            NSApplication.AboutPanelOptionKey.applicationVersion:
                                Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "dev",
                            NSApplication.AboutPanelOptionKey.version: "macOS Edition",
                            NSApplication.AboutPanelOptionKey(rawValue: "Copyright"): "SplitWire Turkey contributors — MIT License"
                        ]
                    )
                }
            }
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }

    func applicationWillTerminate(_ notification: Notification) {
        ByeDPIService.shared.shutdown()
    }
}
