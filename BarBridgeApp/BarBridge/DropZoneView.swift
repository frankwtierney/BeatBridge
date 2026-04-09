import SwiftUI
import UniformTypeIdentifiers

struct DropZoneView: View {
    @ObservedObject var config: SessionConfig
    @ObservedObject var engine: ProcessingEngine
    @State private var isHovering = false
    @State private var dropStatus = ""

    // Accept broad types so we catch Logic's file promises
    private let supportedTypes: [UTType] = [.item]

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "waveform.badge.plus")
                .font(.system(size: 40))
                .foregroundColor(isHovering ? .blue : .secondary)

            Text(isHovering ? "Release to process" : "Drop audio regions here")
                .font(.headline)
                .foregroundColor(isHovering ? .blue : .secondary)

            Text("Drag from Logic Pro, Finder, or any app")
                .font(.caption)
                .foregroundColor(.secondary)

            if !dropStatus.isEmpty {
                Text(dropStatus)
                    .font(.caption2)
                    .foregroundColor(.orange)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 160)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isHovering ? Color.blue.opacity(0.1) : Color.gray.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    isHovering ? Color.blue : Color.gray.opacity(0.3),
                    style: StrokeStyle(lineWidth: 2, dash: [8, 4])
                )
        )
        .onDrop(of: supportedTypes, isTargeted: $isHovering) { providers in
            handleDrop(providers)
            return true
        }
    }

    private func handleDrop(_ providers: [NSItemProvider]) {
        dropStatus = "Receiving \(providers.count) file(s)..."

        for provider in providers {
            // Method 1: Try loading as file representation (handles Logic's file promises)
            let audioTypes: [UTType] = [.aiff, .wav, .audio, .midi]
            var handled = false

            for type in audioTypes {
                if provider.hasItemConformingToTypeIdentifier(type.identifier) {
                    handled = true
                    provider.loadFileRepresentation(forTypeIdentifier: type.identifier) { url, error in
                        if let url = url {
                            // Copy to a temp location since the provided URL is temporary
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
                                    dropStatus = "Copy failed: \(error.localizedDescription)"
                                }
                            }
                        } else if let error = error {
                            DispatchQueue.main.async {
                                dropStatus = "Load failed: \(error.localizedDescription)"
                            }
                        }
                    }
                    break
                }
            }

            // Method 2: Fallback to file URL (Finder drags)
            if !handled && provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
                provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { data, error in
                    guard let data = data as? Data,
                          let url = URL(dataRepresentation: data, relativeTo: nil) else {
                        DispatchQueue.main.async { dropStatus = "Could not read file URL" }
                        return
                    }

                    let ext = url.pathExtension.lowercased()
                    let supported = ["wav", "aif", "aiff", "mid", "midi"]
                    guard supported.contains(ext) else {
                        DispatchQueue.main.async { dropStatus = "Unsupported: .\(ext)" }
                        return
                    }

                    DispatchQueue.main.async {
                        dropStatus = ""
                        engine.processFile(url: url, config: config)
                    }
                }
            }
        }
    }
}
