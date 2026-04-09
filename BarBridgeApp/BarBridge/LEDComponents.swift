import SwiftUI

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
                    .fill(isLit ? segmentColor(index: i) : Color.gray.opacity(0.1))
                    .frame(width: 9, height: 16)
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
                .frame(width: 30, height: 22)
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
