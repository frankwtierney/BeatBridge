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

/// Makes the window transparent with traffic lights but no title bar frame.
struct TransparentWindow: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            guard let window = view.window else { return }
            window.isOpaque = false
            window.backgroundColor = .clear
            window.titlebarAppearsTransparent = true
            window.titleVisibility = .hidden
            // Keep .titled so traffic lights (red/yellow/green) stay visible
            window.styleMask.insert(.titled)
            window.styleMask.insert(.closable)
            window.styleMask.insert(.miniaturizable)
            window.styleMask.insert(.fullSizeContentView)
            window.styleMask.remove(.resizable)
            window.isMovableByWindowBackground = true
            window.level = .floating
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {}
}
