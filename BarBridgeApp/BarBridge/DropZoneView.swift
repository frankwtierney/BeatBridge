import SwiftUI
import UniformTypeIdentifiers

struct DropZoneView: View {
    @ObservedObject var config: SessionConfig
    @ObservedObject var engine: ProcessingEngine
    @State private var isHovering = false

    private let supportedTypes: [UTType] = [.audio, .aiff, .wav, .midi, .fileURL]

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

            Text("Supports multiple files")
                .font(.caption2)
                .foregroundColor(.secondary.opacity(0.7))
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

    private func handleDrop(_ providers: [NSItemProvider]) -> Void {
        for provider in providers {
            // Handle file URLs (covers all file types)
            if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
                provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { data, error in
                    guard let data = data as? Data,
                          let url = URL(dataRepresentation: data, relativeTo: nil) else { return }

                    let ext = url.pathExtension.lowercased()
                    let supported = ["wav", "aif", "aiff", "mid", "midi"]
                    guard supported.contains(ext) else { return }

                    DispatchQueue.main.async {
                        engine.processFile(url: url, config: config)
                    }
                }
            }
        }
    }
}
