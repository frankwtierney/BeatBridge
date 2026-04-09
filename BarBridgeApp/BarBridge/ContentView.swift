import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var config = SessionConfig()
    @StateObject private var engine = ProcessingEngine()
    @State private var isHovering = false
    @State private var dropStatus = ""

    @State private var bpmText = "120"
    @State private var barText = "1.1"
    @State private var editingBPM = false
    @State private var editingStart = false

    private let rackHeight: CGFloat = 120

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
                // IN — square drop zone
                inSection
                    .frame(width: rackHeight, height: rackHeight)
                    .padding(6)

                rackDivider

                // RATE
                RateSelectorView(
                    value: $config.destinationSampleRate,
                    values: SessionConfig.sampleRates
                )
                .frame(width: 110, height: rackHeight)

                rackDivider

                // CENTER: Title + Progress
                centerSection
                    .frame(height: rackHeight)
                    .padding(.horizontal, 16)

                rackDivider

                // BPM
                bpmSection
                    .frame(width: 110, height: rackHeight)

                rackDivider

                // START M.B
                startSection
                    .frame(width: 110, height: rackHeight)

                rackDivider

                // DRAG OUT — square
                dragOutSection
                    .frame(width: rackHeight, height: rackHeight)
                    .padding(6)
            }
            .frame(height: rackHeight + 24)
            .background(rackBackground)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )

            // === FILE LIST ===
            if !engine.files.isEmpty {
                fileList.padding(.top, 6)
            }
        }
        .frame(width: 900)
        .onAppear {
            engine.checkDependencies()
        }
    }

    // MARK: - IN Section (square)

    private var inSection: some View {
        VStack(spacing: 6) {
            Image(systemName: "waveform.badge.plus")
                .font(.system(size: 24))
                .foregroundColor(isHovering ? .blue : .green)

            Text("IN")
                .font(.system(size: 11, weight: .heavy, design: .monospaced))
                .foregroundColor(isHovering ? .blue : .green)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isHovering ? Color.blue.opacity(0.1) : Color.green.opacity(0.02))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(
                            isHovering ? Color.blue.opacity(0.6) : Color.green.opacity(0.25),
                            style: StrokeStyle(lineWidth: 1.5, dash: [6, 4])
                        )
                )
        )
        .onDrop(of: [.item], isTargeted: $isHovering) { providers in
            handleDrop(providers)
            return true
        }
    }

    // MARK: - Center Section

    private var centerSection: some View {
        VStack(spacing: 6) {
            Spacer()
            Image("BeatBridgeLogo")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 4)

            LEDMeter(progress: overallProgress, segments: 20)
                .fixedSize()
            Spacer()
        }
    }

    // MARK: - BPM Section (click to type)

    private var bpmSection: some View {
        VStack(spacing: 4) {
            Spacer()
            HStack(spacing: 4) {
                Image(systemName: "metronome.fill")
                    .font(.system(size: 9))
                    .foregroundColor(.gray)
                RackLabel(text: "BPM")
            }
            .fixedSize()

            // Seven-segment display — click to type
            ZStack {
                if editingBPM {
                    TextField("", text: $bpmText, onCommit: {
                        editingBPM = false
                        syncBPMFromText()
                    })
                    .font(.system(size: 24, weight: .bold, design: .monospaced))
                    .foregroundColor(.green)
                    .multilineTextAlignment(.center)
                    .textFieldStyle(.plain)
                    .frame(width: 80)
                } else {
                    SevenSegmentDisplay(bpmText, height: 24, color: .green)
                }
            }
            .frame(width: 90, height: 38)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.black)
                    .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.gray.opacity(0.3), lineWidth: 0.5))
            )
            .onTapGesture { editingBPM = true }

            HStack(spacing: 6) {
                RackButton(label: "−") { adjustBPM(-1) }
                RackButton(label: "+") { adjustBPM(1) }
            }
            Spacer()
        }
    }

    // MARK: - START Section (M.B — click to type)

    private var startSection: some View {
        VStack(spacing: 4) {
            Spacer()
            HStack(spacing: 4) {
                Image(systemName: "play.fill")
                    .font(.system(size: 8))
                    .foregroundColor(.gray)
                RackLabel(text: "Start M.B")
            }
            .fixedSize()

            // Seven-segment display — click to type
            ZStack {
                if editingStart {
                    TextField("", text: $barText, onCommit: {
                        editingStart = false
                        syncBarFromText()
                    })
                    .font(.system(size: 24, weight: .bold, design: .monospaced))
                    .foregroundColor(.green)
                    .multilineTextAlignment(.center)
                    .textFieldStyle(.plain)
                    .frame(width: 80)
                } else {
                    SevenSegmentDisplay(barText, height: 24, color: .green)
                }
            }
            .frame(width: 90, height: 38)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.black)
                    .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.gray.opacity(0.3), lineWidth: 0.5))
            )
            .onTapGesture { editingStart = true }

            HStack(spacing: 6) {
                RackButton(label: "−") { adjustStart(-1) }
                RackButton(label: "+") { adjustStart(1) }
            }
            Spacer()
        }
    }

    // MARK: - Drag Out Section (square)

    private var dragOutSection: some View {
        VStack(spacing: 6) {
            Image(systemName: "arrow.right.circle.fill")
                .font(.system(size: 24))
                .foregroundColor(latestCompleteFile != nil ? .green : .gray.opacity(0.2))

            Text("DRAG\nOUT")
                .font(.system(size: 9, weight: .heavy, design: .monospaced))
                .foregroundColor(latestCompleteFile != nil ? .green : .gray.opacity(0.2))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
                    colors: [Color.gray.opacity(0.03), Color.gray.opacity(0.2), Color.gray.opacity(0.03)],
                    startPoint: .top, endPoint: .bottom
                )
            )
            .frame(width: 1)
            .padding(.vertical, 10)
    }

    // MARK: - File List

    private var fileList: some View {
        VStack(alignment: .leading, spacing: 3) {
            ForEach(engine.files) { file in
                HStack(spacing: 8) {
                    Group {
                        switch file.status {
                        case .queued: Image(systemName: "clock").foregroundColor(.secondary)
                        case .processing: ProgressView().scaleEffect(0.5)
                        case .complete: Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                        case .error: Image(systemName: "xmark.circle.fill").foregroundColor(.red)
                        }
                    }.frame(width: 14)

                    Text(file.outputName.isEmpty ? file.inputName : file.outputName)
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(file.isComplete ? .green : .white.opacity(0.7))
                        .lineLimit(1)

                    if case .error(let msg) = file.status {
                        Text(msg).font(.system(size: 9)).foregroundColor(.red).lineLimit(1)
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

    // MARK: - Helpers

    private func adjustBPM(_ delta: Double) {
        config.bpm = max(1, min(999, config.bpm + delta))
        bpmText = "\(Int(config.bpm))"
    }

    private func adjustStart(_ delta: Int) {
        // + increments beat, wrapping to next measure
        config.beatNumber += delta
        if config.beatNumber < 1 {
            config.barNumber = max(1, config.barNumber - 1)
            config.beatNumber = 4 // wrap to beat 4 of previous measure
        } else if config.beatNumber > 4 {
            config.barNumber += 1
            config.beatNumber = 1 // wrap to beat 1 of next measure
        }
        config.barNumber = max(1, config.barNumber)
        barText = config.barPositionDisplay
    }

    private func syncBPMFromText() {
        if let val = Double(bpmText), val >= 1, val <= 999 {
            config.bpm = val
        }
        bpmText = "\(Int(config.bpm))"
    }

    private func syncBarFromText() {
        let parts = barText.split(separator: ".")
        if let bar = Int(parts.first ?? "") {
            config.barNumber = max(1, bar)
        }
        if parts.count > 1, let beat = Int(parts.last ?? "") {
            config.beatNumber = max(1, min(beat, 4))
        }
        barText = config.barPositionDisplay
    }

    // MARK: - Drop Handling

    private func handleDrop(_ providers: [NSItemProvider]) {
        dropStatus = "..."
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
                                DispatchQueue.main.async { dropStatus = "" }
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

extension View {
    @ViewBuilder
    func `if`<Transform: View>(_ condition: Bool, transform: (Self) -> Transform) -> some View {
        if condition { transform(self) } else { self }
    }
}
