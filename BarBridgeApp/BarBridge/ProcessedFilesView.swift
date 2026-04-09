import SwiftUI
import UniformTypeIdentifiers

struct ProcessedFilesView: View {
    let files: [ProcessedFile]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Processed Files — drag to DAW")
                .font(.caption.bold())
                .foregroundColor(.secondary)

            ForEach(files) { file in
                ProcessedFileRow(file: file)
            }
        }
    }
}

struct ProcessedFileRow: View {
    let file: ProcessedFile

    var body: some View {
        HStack(spacing: 10) {
            // Status indicator
            statusIcon

            // File info
            VStack(alignment: .leading, spacing: 2) {
                Text(file.inputName)
                    .font(.caption.bold())
                    .lineLimit(1)

                if file.isComplete, let output = file.outputPath {
                    Text(output.lastPathComponent)
                        .font(.caption2)
                        .foregroundColor(.green)
                }

                if case .error(let msg) = file.status {
                    Text(msg)
                        .font(.caption2)
                        .foregroundColor(.red)
                        .lineLimit(2)
                }

                if case .processing(let progress) = file.status {
                    ProgressView(value: progress)
                        .progressViewStyle(.linear)
                }
            }

            Spacer()

            // Reveal in Finder button
            if file.isComplete, let output = file.outputPath {
                Button(action: { NSWorkspace.shared.activateFileViewerSelecting([output]) }) {
                    Image(systemName: "folder")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("Reveal in Finder")
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(file.isComplete ? Color.green.opacity(0.06) : Color.gray.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(file.isComplete ? Color.green.opacity(0.2) : Color.clear)
        )
        // DRAG OUT — this is what makes the file draggable to Reaper
        .if(file.isComplete && file.outputPath != nil) { view in
            view.onDrag {
                NSItemProvider(contentsOf: file.outputPath!)!
            }
        }
    }

    @ViewBuilder
    private var statusIcon: some View {
        switch file.status {
        case .queued:
            Image(systemName: "clock")
                .foregroundColor(.secondary)
        case .processing:
            ProgressView()
                .scaleEffect(0.6)
                .frame(width: 16, height: 16)
        case .complete:
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
        case .error:
            Image(systemName: "xmark.circle.fill")
                .foregroundColor(.red)
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
