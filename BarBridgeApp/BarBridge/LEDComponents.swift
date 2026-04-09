import SwiftUI

/// LED-style segmented display — glowing green/amber text on dark background.
struct LEDDisplay: View {
    let text: String
    let width: CGFloat
    let fontSize: CGFloat

    init(_ text: String, width: CGFloat = 70, fontSize: CGFloat = 22) {
        self.text = text
        self.width = width
        self.fontSize = fontSize
    }

    var body: some View {
        Text(text)
            .font(.system(size: fontSize, weight: .bold, design: .monospaced))
            .foregroundColor(.green)
            .shadow(color: .green.opacity(0.6), radius: 4)
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

    init(progress: Double, segments: Int = 20) {
        self.progress = progress
        self.segments = segments
    }

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<segments, id: \.self) { i in
                let threshold = Double(i) / Double(segments)
                let isLit = progress > threshold

                RoundedRectangle(cornerRadius: 1)
                    .fill(isLit ? segmentColor(index: i) : Color.gray.opacity(0.15))
                    .frame(width: 8, height: 16)
                    .shadow(color: isLit ? segmentColor(index: i).opacity(0.5) : .clear, radius: 2)
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
            .font(.system(size: 8, weight: .semibold))
            .foregroundColor(.gray)
            .textCase(.uppercase)
    }
}
