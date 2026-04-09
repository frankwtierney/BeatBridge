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

/// The window level to use: floating (3) is the standard "above all normal windows" level.
/// Using .floating rather than .statusBar avoids edge-case issues where macOS treats
/// very high window levels specially (e.g., forcing them behind the menu bar layer).
private let alwaysOnTopLevel = NSWindow.Level.floating

/// Transparent title bar with traffic lights visible, content goes edge-to-edge.
/// Keeps the window above all other application windows even when the app loses focus.
struct TransparentWindow: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            guard let window = view.window else { return }
            Self.configureWindow(window)
            context.coordinator.observeWindow(window)
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        // SwiftUI calls updateNSView on every state change. Re-enforce the level
        // here because SwiftUI may have reset it during a layout pass.
        DispatchQueue.main.async {
            guard let window = nsView.window else { return }
            if window.level != alwaysOnTopLevel {
                window.level = alwaysOnTopLevel
            }
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    /// One-time window configuration.
    static func configureWindow(_ window: NSWindow) {
        window.isOpaque = false
        window.backgroundColor = .clear
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        // Keep .titled so traffic lights stay visible
        window.styleMask.insert(.titled)
        window.styleMask.insert(.closable)
        window.styleMask.insert(.miniaturizable)
        window.styleMask.insert(.fullSizeContentView)
        window.styleMask.remove(.resizable)
        window.isMovableByWindowBackground = true
        window.level = alwaysOnTopLevel
        window.titlebarSeparatorStyle = .none
        window.collectionBehavior = [.canJoinAllSpaces, .stationary]
        // Prevent hiding when the app is deactivated
        window.hidesOnDeactivate = false
    }

    // MARK: - Coordinator

    /// Observes window and application notifications to re-apply the floating level
    /// whenever macOS or SwiftUI resets it.
    class Coordinator: NSObject {
        private var levelObservation: NSKeyValueObservation?
        private var notificationTokens: [NSObjectProtocol] = []
        private weak var observedWindow: NSWindow?

        func observeWindow(_ window: NSWindow) {
            guard observedWindow !== window else { return }
            cleanup()
            observedWindow = window

            // 1. KVO on the window's level property -- catches any programmatic reset
            //    by SwiftUI or AppKit internals.
            levelObservation = window.observe(\.level, options: [.new]) { [weak self] win, _ in
                guard self != nil else { return }
                if win.level != alwaysOnTopLevel {
                    // Defer to next run-loop tick to avoid re-entrant KVO issues
                    DispatchQueue.main.async {
                        win.level = alwaysOnTopLevel
                    }
                }
            }

            // 2. App resigned active -- another app took focus. Re-enforce level.
            let resignToken = NotificationCenter.default.addObserver(
                forName: NSApplication.didResignActiveNotification,
                object: nil, queue: .main
            ) { [weak window] _ in
                guard let window = window else { return }
                window.level = alwaysOnTopLevel
                // Also order front to ensure visibility
                window.orderFrontRegardless()
            }
            notificationTokens.append(resignToken)

            // 3. Window did resign key -- e.g., user clicked into another window in the
            //    same or different app. Re-enforce level.
            let resignKeyToken = NotificationCenter.default.addObserver(
                forName: NSWindow.didResignKeyNotification,
                object: window, queue: .main
            ) { [weak window] _ in
                guard let window = window else { return }
                window.level = alwaysOnTopLevel
            }
            notificationTokens.append(resignKeyToken)

            // 4. Window did update -- fires frequently; use as a safety net.
            let updateToken = NotificationCenter.default.addObserver(
                forName: NSWindow.didUpdateNotification,
                object: window, queue: .main
            ) { [weak window] _ in
                guard let window = window else { return }
                if window.level != alwaysOnTopLevel {
                    window.level = alwaysOnTopLevel
                }
            }
            notificationTokens.append(updateToken)
        }

        private func cleanup() {
            levelObservation?.invalidate()
            levelObservation = nil
            for token in notificationTokens {
                NotificationCenter.default.removeObserver(token)
            }
            notificationTokens.removeAll()
        }

        deinit { cleanup() }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Ensure the app does not hide windows when it loses focus
        // (belt-and-suspenders alongside hidesOnDeactivate = false on the window)
    }

    func applicationDidResignActive(_ notification: Notification) {
        // Re-enforce floating level on all windows when the app loses focus
        for window in NSApplication.shared.windows {
            if window.level != alwaysOnTopLevel {
                window.level = alwaysOnTopLevel
            }
        }
    }
}
