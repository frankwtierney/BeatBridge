import SwiftUI

struct SettingsView: View {
    @ObservedObject var config: SessionConfig

    var body: some View {
        VStack(spacing: 8) {
            Text("Session Settings")
                .font(.subheadline.bold())

            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("BPM").font(.caption).foregroundColor(.secondary)
                    TextField("BPM", value: $config.bpm, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 90)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Time Sig").font(.caption).foregroundColor(.secondary)
                    Picker("", selection: Binding(
                        get: { "\(config.beatsPerBar)/\(config.beatValue)" },
                        set: { val in
                            let parts = val.split(separator: "/")
                            if parts.count == 2 {
                                config.beatsPerBar = Int(parts[0]) ?? 4
                                config.beatValue = Int(parts[1]) ?? 4
                            }
                        }
                    )) {
                        ForEach(SessionConfig.timeSignatures, id: \.0) { ts in
                            Text("\(ts.0)/\(ts.1)").tag("\(ts.0)/\(ts.1)")
                        }
                    }
                    .frame(width: 90)
                }
            }

            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Dest. Rate (Hz)").font(.caption).foregroundColor(.secondary)
                    Picker("", selection: $config.destinationSampleRate) {
                        ForEach(SessionConfig.sampleRates, id: \.self) { sr in
                            Text("\(sr)").tag(sr)
                        }
                    }
                    .frame(width: 120)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Bar Position").font(.caption).foregroundColor(.secondary)
                    HStack(spacing: 4) {
                        TextField("Bar", value: $config.barNumber, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 50)
                        Text(".").foregroundColor(.secondary)
                        TextField("Beat", value: $config.beatNumber, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 50)
                    }
                }
            }

            // Preview of the label
            Text("Tag: \(config.barPositionLabel) · \(Int(config.bpm))BPM")
                .font(.caption2)
                .foregroundColor(.green.opacity(0.8))
        }
    }
}
