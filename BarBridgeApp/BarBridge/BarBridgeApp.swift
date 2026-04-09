import SwiftUI

@main
struct BarBridgeApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .background(TransparentWindow())
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
    }
}

/// Makes the window borderless, transparent, and draggable.
struct TransparentWindow: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            guard let window = view.window else { return }
            window.isOpaque = false
            window.backgroundColor = .clear
            window.titlebarAppearsTransparent = true
            window.titleVisibility = .hidden
            window.styleMask.remove(.titled)
            window.styleMask.insert(.fullSizeContentView)
            window.isMovableByWindowBackground = true
            window.level = .floating
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}

/// Handles app-level setup.
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Keep running when window is closed (optional)
    }
}
