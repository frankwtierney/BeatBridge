import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var config = SessionConfig()
    @StateObject private var engine = ProcessingEngine()
    @State private var isHovering = false
    @State private var dropStatus = ""

    /// Overall processing progress (average of all files)
    private var overallProgress: Double {
        guard !engine.files.isEmpty else { return 0 }
        return engine.files.map(\.progress).reduce(0, +) / Double(engine.files.count)
    }

    /// The latest completed file (for drag-out)
    private var latestCompleteFile: ProcessedFile? {
        engine.files.last(where: { $0.isComplete })
    }

    var body: some View {
        VStack(spacing: 0) {
            // Main rack unit
            HStack(spacing: 0) {
                // === IN SECTION ===
                inSection
                    .frame(width: 70)

                divider

                // === RATE KNOB ===
                IntKnobView(
                    label: "Rate (Hz)",
                    value: $config.destinationSampleRate,
                    values: SessionConfig.sampleRates
                )
                .frame(width: 80)

                divider

                // === CENTER: Title + Progress ===
                centerSection
                    .frame(minWidth: 200)

                divider

                // === BPM ===
                bpmSection
                    .frame(width: 80)

                divider

                // === BAR POSITION ===
                barPositionSection
                    .frame(width: 80)

                divider

                // === DRAG OUT ===
                dragOutSection
                    .frame(width: 70)
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 8)
            .background(rackBackground)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )

            // File list below rack
            if !engine.files.isEmpty {
                fileList
                    .padding(.top, 8)
            }
        }
        .padding(12)
        .frame(width: 680)
        .onAppear {
            engine.checkDependencies()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                NSApplication.shared.windows.first?.level = .floating
            }
        }
    }

    // MARK: - Sections

    private var inSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "waveform.badge.plus")
                .font(.system(size: 20))
                .foregroundColor(isHovering ? .blue : .green)

            Text("IN")
                .font(.system(size: 10, weight: .heavy, design: .monospaced))
                .foregroundColor(isHovering ? .blue : .green)

            if !dropStatus.isEmpty {
                Text(dropStatus)
                    .font(.system(size: 7))
                    .foregroundColor(.orange)
                    .lineLimit(2)
            }
        }
        .frame(maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isHovering ? Color.blue.opacity(0.1) : Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .strokeBorder(
                            isHovering ? Color.blue.opacity(0.5) : Color.green.opacity(0.2),
                            style: StrokeStyle(lineWidth: 1, dash: [4, 3])
                        )
                )
        )
        .padding(4)
        .onDrop(of: [.item], isTargeted: $isHovering) { providers in
            handleDrop(providers)
            return true
        }
    }

    private var centerSection: some View {
        VStack(spacing: 10) {
            // Title
            HStack(spacing: 6) {
                Text("BEAT")
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                Image(systemName: "bridge.fill")
                    .font(.system(size: 10))
                    .foregroundColor(.purple)
                Text("BRIDGE")
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
            }

            // Progress meter
            VStack(spacing: 4) {
                LEDMeter(progress: overallProgress, segments: 24)
                RackLabel(text: "Progress")
            }
        }
    }

    private var bpmSection: some View {
        VStack(spacing: 6) {
            RackLabel(text: "BPM")
            LEDDisplay("\(Int(config.bpm))", width: 56, fontSize: 20)

            // Small +/- buttons
            HStack(spacing: 8) {
                Button(action: { config.bpm = max(1, config.bpm - 1) }) {
                    Image(systemName: "minus")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.gray)
                }
                .buttonStyle(.plain)

                Button(action: { config.bpm = min(999, config.bpm + 1) }) {
                    Image(systemName: "plus")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.gray)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var barPositionSection: some View {
        VStack(spacing: 6) {
            RackLabel(text: "Start B.M")
            LEDDisplay(config.barPositionDisplay, width: 56, fontSize: 20)

            HStack(spacing: 4) {
                Button(action: { config.barNumber = max(1, config.barNumber - 1) }) {
                    Text("B-").font(.system(size: 7, weight: .bold, design: .monospaced))
                        .foregroundColor(.gray)
                }
                .buttonStyle(.plain)

                Button(action: { config.barNumber += 1 }) {
                    Text("B+").font(.system(size: 7, weight: .bold, design: .monospaced))
                        .foregroundColor(.gray)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var dragOutSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "arrow.right.circle.fill")
                .font(.system(size: 20))
                .foregroundColor(latestCompleteFile != nil ? .green : .gray.opacity(0.3))

            Text("DRAG\nOUT")
                .font(.system(size: 9, weight: .heavy, design: .monospaced))
                .foregroundColor(latestCompleteFile != nil ? .green : .gray.opacity(0.3))
                .multilineTextAlignment(.center)
        }
        .frame(maxHeight: .infinity)
        .if(latestCompleteFile?.outputPath != nil) { view in
            view.onDrag {
                NSItemProvider(contentsOf: latestCompleteFile!.outputPath!)!
            }
        }
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.gray.opacity(0.2))
            .frame(width: 1)
            .padding(.vertical, 8)
    }

    // MARK: - File List

    private var fileList: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(engine.files) { file in
                HStack(spacing: 8) {
                    // Status icon
                    Group {
                        switch file.status {
                        case .queued:
                            Image(systemName: "clock").foregroundColor(.secondary)
                        case .processing:
                            ProgressView().scaleEffect(0.5)
                        case .complete:
                            Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                        case .error:
                            Image(systemName: "xmark.circle.fill").foregroundColor(.red)
                        }
                    }
                    .frame(width: 16)

                    // Filename
                    VStack(alignment: .leading, spacing: 1) {
                        Text(file.outputName.isEmpty ? file.inputName : file.outputName)
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundColor(file.isComplete ? .green : .white)
                            .lineLimit(1)

                        if case .error(let msg) = file.status {
                            Text(msg)
                                .font(.system(size: 9))
                                .foregroundColor(.red)
                                .lineLimit(1)
                        }
                    }

                    Spacer()

                    // Drag handle for individual files
                    if file.isComplete, let output = file.outputPath {
                        Image(systemName: "line.3.horizontal")
                            .font(.system(size: 10))
                            .foregroundColor(.green.opacity(0.5))
                            .onDrag {
                                NSItemProvider(contentsOf: output)!
                            }
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.03))
                )
            }
        }
    }

    // MARK: - Rack Background

    private var rackBackground: some View {
        LinearGradient(
            colors: [
                Color(white: 0.18),
                Color(white: 0.12),
                Color(white: 0.10),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    // MARK: - Drop Handling

    private func handleDrop(_ providers: [NSItemProvider]) {
        dropStatus = "Receiving..."

        for provider in providers {
            let audioTypes: [UTType] = [.aiff, .wav, .audio, .midi]
            var handled = false

            for type in audioTypes {
                if provider.hasItemConformingToTypeIdentifier(type.identifier) {
                    handled = true
                    provider.loadFileRepresentation(forTypeIdentifier: type.identifier) { url, error in
                        if let url = url {
                            let tempDir = FileManager.default.temporaryDirectory
                            let dest = tempDir.appendingPathComponent(url.lastPathComponent)
                            try? FileManager.default.removeItem(at: dest)
                            do {
                                try FileManager.default.copyItem(at: url, to: dest)
                                DispatchQueue.main.async {
                                    dropStatus = ""
                                    engine.processFile(url: dest, config: config)
                                }
                            } catch {
                                DispatchQueue.main.async {
                                    dropStatus = "Error: \(error.localizedDescription)"
                                }
                            }
                        }
                    }
                    break
                }
            }

            if !handled && provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
                provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { data, error in
                    guard let data = data as? Data,
                          let url = URL(dataRepresentation: data, relativeTo: nil) else { return }
                    let ext = url.pathExtension.lowercased()
                    guard ["wav", "aif", "aiff", "mid", "midi"].contains(ext) else { return }
                    DispatchQueue.main.async {
                        dropStatus = ""
                        engine.processFile(url: url, config: config)
                    }
                }
            }
        }
    }
}

// Conditional modifier helper
extension View {
    @ViewBuilder
    func `if`<Transform: View>(_ condition: Bool, transform: (Self) -> Transform) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
