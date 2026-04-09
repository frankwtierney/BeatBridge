import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var config = SessionConfig()
    @StateObject private var engine = ProcessingEngine()

    var body: some View {
        VStack(spacing: 12) {
            // Title
            Text("BarBridge v1.0")
                .font(.title.bold())
            Text("Digital Timing Jig")
                .font(.caption)
                .foregroundColor(.secondary)

            Divider()

            // Session Settings
            SettingsView(config: config)

            Divider()

            // Drop Zone
            DropZoneView(config: config, engine: engine)

            // Processed Files (with drag-out)
            if !engine.files.isEmpty {
                ProcessedFilesView(files: engine.files)
            }

            Divider()

            // Footer
            HStack(spacing: 16) {
                Label(engine.ffmpegVersion ?? "FFmpeg: Not found",
                      systemImage: engine.ffmpegVersion != nil ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.caption2)
                    .foregroundColor(engine.ffmpegVersion != nil ? .green : .red)

                Text("Cache: \(engine.files.filter { $0.isComplete }.count) files")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(20)
        .frame(width: 480)
        .onAppear {
            engine.checkDependencies()
            // Make window float on top
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                NSApplication.shared.windows.first?.level = .floating
            }
        }
    }
}
