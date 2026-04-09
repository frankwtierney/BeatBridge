import SwiftUI

/// Rate selector with LED display and circular push buttons.
/// Matches the visual style of the BPM and START sections.
struct RateSelectorView: View {
    @Binding var value: Int
    let values: [Int]

    var body: some View {
        VStack(spacing: 5) {
            Spacer()

            // Label with icon
            HStack(spacing: 4) {
                Image(systemName: "waveform")
                    .font(.system(size: 9))
                    .foregroundColor(.gray)
                RackLabel(text: "Rate (Hz)")
            }
            .fixedSize()

            // Seven-segment display showing current rate
            ZStack {
                SevenSegmentDisplay(formatRateDisplay(value), height: 24, color: .green)
            }
            .frame(width: 90, height: 38)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.black)
                    .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.gray.opacity(0.3), lineWidth: 0.5))
            )

            // Four circular push buttons
            HStack(spacing: 6) {
                ForEach(values, id: \.self) { rate in
                    RatePushButton(
                        isSelected: value == rate,
                        action: { value = rate }
                    )
                }
            }
            .padding(.top, 2)

            Spacer()
        }
    }

    private func formatRateDisplay(_ rate: Int) -> String {
        let thousands = rate / 1000
        let remainder = (rate % 1000) / 100
        if remainder == 0 { return "\(thousands)k" }
        return "\(thousands).\(remainder)k"
    }
}

/// Circular push button with knob-like gradient — glows when selected.
struct RatePushButton: View {
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Circle()
                .fill(
                    RadialGradient(
                        colors: isSelected
                            ? [Color(white: 0.45), Color(white: 0.25)]
                            : [Color(white: 0.28), Color(white: 0.14)],
                        center: .topLeading,
                        startRadius: 0,
                        endRadius: 12
                    )
                )
                .frame(width: 16, height: 16)
                .overlay(
                    Circle()
                        .fill(isSelected ? Color.blue.opacity(0.7) : Color.clear)
                        .frame(width: 6, height: 6)
                        .shadow(color: isSelected ? .blue.opacity(0.8) : .clear, radius: 4)
                )
                .overlay(
                    Circle()
                        .stroke(isSelected ? Color.blue.opacity(0.4) : Color.gray.opacity(0.2), lineWidth: 0.5)
                )
                .shadow(color: .black.opacity(0.4), radius: 2, y: 1)
        }
        .buttonStyle(.plain)
    }
}

/// Arc shape helper
struct Arc: Shape {
    let startAngle: Angle
    let endAngle: Angle
    let clockwise: Bool

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addArc(
            center: CGPoint(x: rect.midX, y: rect.midY),
            radius: rect.width / 2,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: clockwise
        )
        return path
    }
}
