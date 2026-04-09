import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var config = SessionConfig()
    @StateObject private var engine = ProcessingEngine()
    @State private var isHovering = false
    @State private var dropStatus = ""

    // Editable string bindings for LED displays
    @State private var bpmText = "120"
    @State private var barText = "1.1"

    private var overallProgress: Double {
        guard !engine.files.isEmpty else { return 0 }
        return engine.files.map(\.progress).reduce(0, +) / Double(engine.files.count)
    }

    private var latestCompleteFile: ProcessedFile? {
        engine.files.last(where: { $0.isComplete })
    }

    var body: some View {
        VStack(spacing: 0) {
            // === MAIN RACK UNIT ===
            HStack(spacing: 0) {
                // IN
                inSection
                    .frame(width: 90)

                rackDivider

                // RATE KNOB
                RateKnobView(
                    label: "Rate (Hz)",
                    value: $config.destinationSampleRate,
                    values: SessionConfig.sampleRates
                )
                .frame(width: 100)
                .padding(.vertical, 8)

                rackDivider

                // CENTER: Title + Progress
                centerSection
                    .padding(.horizontal, 16)
                    .frame(minWidth: 220)

                rackDivider

                // BPM
                VStack(spacing: 6) {
                    LEDDisplay("BPM", text: $bpmText, width: 85, fontSize: 30)
                    HStack(spacing: 6) {
                        RackButton(label: "−") { adjustBPM(-1) }
                        RackButton(label: "+") { adjustBPM(1) }
                    }
                }
                .frame(width: 100)
                .padding(.vertical, 8)
                .onChange(of: bpmText) { _ in syncBPMFromText() }

                rackDivider

                // START B.M
                VStack(spacing: 6) {
                    LEDDisplay("Start B.M", text: $barText, width: 85, fontSize: 30)
                    HStack(spacing: 6) {
                        RackButton(label: "B−") { adjustBar(-1) }
                        RackButton(label: "B+") { adjustBar(1) }
                    }
                }
                .frame(width: 100)
                .padding(.vertical, 8)
                .onChange(of: barText) { _ in syncBarFromText() }

                rackDivider

                // DRAG OUT
                dragOutSection
                    .frame(width: 80)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 6)
            .background(rackBackground)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )

            // === FILE LIST ===
            if !engine.files.isEmpty {
                fileList
                    .padding(.top, 6)
            }
        }
        .padding(10)
        .frame(width: 780)
        .onAppear {
            engine.checkDependencies()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                NSApplication.shared.windows.first?.level = .floating
            }
        }
    }

    // MARK: - IN Section

    private var inSection: some View {
        VStack(spacing: 10) {
            Image(systemName: "waveform.badge.plus")
                .font(.system(size: 24))
                .foregroundColor(isHovering ? .blue : .green)

            Text("IN")
                .font(.system(size: 11, weight: .heavy, design: .monospaced))
                .foregroundColor(isHovering ? .blue : .green)

            if !dropStatus.isEmpty {
                Text(dropStatus)
                    .font(.system(size: 7))
                    .foregroundColor(.orange)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxHeight: .infinity)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isHovering ? Color.blue.opacity(0.1) : Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .strokeBorder(
                            isHovering ? Color.blue.opacity(0.6) : Color.green.opacity(0.25),
                            style: StrokeStyle(lineWidth: 1.5, dash: [6, 4])
                        )
                )
                .padding(4)
        )
        .onDrop(of: [.item], isTargeted: $isHovering) { providers in
            handleDrop(providers)
            return true
        }
    }

    // MARK: - Center Section

    private var centerSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Text("BEAT")
                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                Image(systemName: "bridge.fill")
                    .font(.system(size: 11))
                    .foregroundColor(.purple)
                Text("BRIDGE")
                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
            }

            LEDMeter(progress: overallProgress, segments: 24)

            RackLabel(text: "Progress")
        }
    }

    // MARK: - Drag Out Section

    private var dragOutSection: some View {
        VStack(spacing: 10) {
            Image(systemName: "arrow.right.circle.fill")
                .font(.system(size: 24))
                .foregroundColor(latestCompleteFile != nil ? .green : .gray.opacity(0.25))

            Text("DRAG\nOUT")
                .font(.system(size: 9, weight: .heavy, design: .monospaced))
                .foregroundColor(latestCompleteFile != nil ? .green : .gray.opacity(0.25))
                .multilineTextAlignment(.center)
        }
        .frame(maxHeight: .infinity)
        .padding(.horizontal, 8)
        .if(latestCompleteFile?.outputPath != nil) { view in
            view.onDrag {
                NSItemProvider(contentsOf: latestCompleteFile!.outputPath!)!
            }
        }
    }

    // MARK: - Divider

    private var rackDivider: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [Color.gray.opacity(0.05), Color.gray.opacity(0.2), Color.gray.opacity(0.05)],
                    startPoint: .top, endPoint: .bottom
                )
            )
            .frame(width: 1)
            .padding(.vertical, 6)
    }

    // MARK: - File List

    private var fileList: some View {
        VStack(alignment: .leading, spacing: 3) {
            ForEach(engine.files) { file in
                HStack(spacing: 8) {
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
                    .frame(width: 14)

                    Text(file.outputName.isEmpty ? file.inputName : file.outputName)
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(file.isComplete ? .green : .white.opacity(0.7))
                        .lineLimit(1)

                    if case .error(let msg) = file.status {
                        Text(msg)
                            .font(.system(size: 9))
                            .foregroundColor(.red)
                            .lineLimit(1)
                    }

                    Spacer()

                    if file.isComplete, let output = file.outputPath {
                        Image(systemName: "line.3.horizontal")
                            .font(.system(size: 9))
                            .foregroundColor(.green.opacity(0.4))
                            .onDrag { NSItemProvider(contentsOf: output)! }
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(RoundedRectangle(cornerRadius: 3).fill(Color.white.opacity(0.02)))
            }
        }
    }

    // MARK: - Background

    private var rackBackground: some View {
        LinearGradient(
            colors: [Color(white: 0.16), Color(white: 0.11), Color(white: 0.09)],
            startPoint: .top, endPoint: .bottom
        )
    }

    // MARK: - BPM / Bar Helpers

    private func adjustBPM(_ delta: Double) {
        config.bpm = max(1, min(999, config.bpm + delta))
        bpmText = "\(Int(config.bpm))"
    }

    private func adjustBar(_ delta: Int) {
        config.barNumber = max(1, config.barNumber + delta)
        barText = config.barPositionDisplay
    }

    private func syncBPMFromText() {
        if let val = Double(bpmText), val >= 1, val <= 999 {
            config.bpm = val
        }
    }

    private func syncBarFromText() {
        let parts = barText.split(separator: ".")
        if let bar = Int(parts.first ?? "") {
            config.barNumber = max(1, bar)
        }
        if parts.count > 1, let beat = Int(parts.last ?? "") {
            config.beatNumber = max(1, beat)
        }
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
                                    dropStatus = "Error"
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
