import SwiftUI

/// LED-style display that shows digital clock numbers.
/// Click to edit the value by typing.
struct LEDDisplay: View {
    let label: String
    @Binding var text: String
    let width: CGFloat
    let fontSize: CGFloat
    @State private var isEditing = false

    init(_ label: String, text: Binding<String>, width: CGFloat = 80, fontSize: CGFloat = 28) {
        self.label = label
        self._text = text
        self.width = width
        self.fontSize = fontSize
    }

    var body: some View {
        VStack(spacing: 6) {
            RackLabel(text: label)

            ZStack {
                if isEditing {
                    TextField("", text: $text, onCommit: { isEditing = false })
                        .font(.system(size: fontSize, weight: .bold, design: .monospaced))
                        .foregroundColor(.green)
                        .multilineTextAlignment(.center)
                        .textFieldStyle(.plain)
                        .frame(width: width - 12)
                } else {
                    Text(text)
                        .font(.system(size: fontSize, weight: .bold, design: .monospaced))
                        .foregroundColor(.green)
                        .shadow(color: .green.opacity(0.6), radius: 6)
                        .shadow(color: .green.opacity(0.3), radius: 12)
                }
            }
            .frame(width: width, height: fontSize + 16)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.black)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 0.5)
                    )
                    .shadow(color: .green.opacity(isEditing ? 0.2 : 0.05), radius: 8)
            )
            .onTapGesture {
                isEditing = true
            }
        }
    }
}

/// Read-only LED display (no editing).
struct LEDLabel: View {
    let text: String
    let width: CGFloat
    let fontSize: CGFloat
    let color: Color

    init(_ text: String, width: CGFloat = 70, fontSize: CGFloat = 20, color: Color = .green) {
        self.text = text
        self.width = width
        self.fontSize = fontSize
        self.color = color
    }

    var body: some View {
        Text(text)
            .font(.system(size: fontSize, weight: .bold, design: .monospaced))
            .foregroundColor(color)
            .shadow(color: color.opacity(0.6), radius: 4)
            .frame(width: width, height: fontSize + 12)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.black)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 0.5)
                    )
            )
    }
}

/// Segmented LED progress meter — green → yellow → orange like a VU meter.
struct LEDMeter: View {
    let progress: Double
    let segments: Int

    init(progress: Double, segments: Int = 24) {
        self.progress = progress
        self.segments = segments
    }

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<segments, id: \.self) { i in
                let threshold = Double(i) / Double(segments)
                let isLit = progress > threshold

                RoundedRectangle(cornerRadius: 1)
                    .fill(isLit ? segmentColor(index: i) : Color.gray.opacity(0.12))
                    .frame(width: 10, height: 18)
                    .shadow(color: isLit ? segmentColor(index: i).opacity(0.5) : .clear, radius: 3)
            }
        }
    }

    private func segmentColor(index: Int) -> Color {
        let ratio = Double(index) / Double(segments)
        if ratio < 0.5 { return .green }
        if ratio < 0.75 { return .yellow }
        return .orange
    }
}

/// Small label text used throughout the rack UI.
struct RackLabel: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 9, weight: .semibold))
            .foregroundColor(.gray)
            .textCase(.uppercase)
            .tracking(1)
    }
}

/// Styled +/- button for rack controls.
struct RackButton: View {
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(.white.opacity(0.7))
                .frame(width: 28, height: 22)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
                        )
                )
        }
        .buttonStyle(.plain)
    }
}
