import SwiftUI

/// Rotary knob that snaps to fixed rate positions with labels at each tick,
/// like a compressor ratio knob. No progress arc — just pointer + ticks.
struct RateKnobView: View {
    let label: String
    @Binding var value: Int
    let values: [Int]
    @State private var showDropdown = false
    @State private var dragStartIndex: Int = 0

    private var currentIndex: Int {
        values.firstIndex(of: value) ?? 0
    }

    private let startAngle: Double = 225
    private let totalSweep: Double = 270
    private let knobRadius: CGFloat = 50

    private func angleForIndex(_ i: Int) -> Double {
        guard values.count > 1 else { return startAngle }
        return startAngle - Double(i) / Double(values.count - 1) * totalSweep
    }

    private var normalizedValue: Double {
        guard values.count > 1 else { return 0 }
        return Double(currentIndex) / Double(values.count - 1)
    }

    private var pointerAngle: Angle {
        .degrees(startAngle - normalizedValue * totalSweep)
    }

    var body: some View {
        VStack(spacing: 2) {
            RackLabel(text: label)

            ZStack {
                // Rate labels positioned around the arc
                ForEach(0..<values.count, id: \.self) { i in
                    let angle = angleForIndex(i)
                    let rad = angle * .pi / 180
                    let labelR: CGFloat = knobRadius * 0.82
                    let x = -cos(rad) * labelR
                    let y = -sin(rad) * labelR

                    Text(formatRateShort(values[i]))
                        .font(.system(size: 9, weight: i == currentIndex ? .bold : .regular, design: .monospaced))
                        .foregroundColor(i == currentIndex ? .white : .gray.opacity(0.5))
                        .position(x: knobRadius + x, y: knobRadius + y)
                }

                // Track arc (subtle, no fill/progress)
                Arc(startAngle: .degrees(-startAngle), endAngle: .degrees(-startAngle + totalSweep), clockwise: false)
                    .stroke(Color.gray.opacity(0.15), lineWidth: 2)
                    .frame(width: knobRadius * 0.88, height: knobRadius * 0.88)

                // Tick marks at each snap position
                ForEach(0..<values.count, id: \.self) { i in
                    let tickAngle = angleForIndex(i)
                    Rectangle()
                        .fill(i == currentIndex ? Color.white : Color.gray.opacity(0.4))
                        .frame(width: i == currentIndex ? 2 : 1.5, height: i == currentIndex ? 8 : 6)
                        .offset(y: -(knobRadius * 0.34))
                        .rotationEffect(.degrees(-tickAngle))
                }

                // Knob body
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color(white: 0.38), Color(white: 0.15)],
                            center: .topLeading,
                            startRadius: 0,
                            endRadius: 30
                        )
                    )
                    .frame(width: 42, height: 42)
                    .shadow(color: .black.opacity(0.6), radius: 4, y: 2)

                // Pointer line
                Capsule()
                    .fill(Color.white.opacity(0.9))
                    .frame(width: 2.5, height: 14)
                    .offset(y: -12)
                    .rotationEffect(pointerAngle)
            }
            .frame(width: knobRadius * 2, height: knobRadius * 2)
            .gesture(
                DragGesture(minimumDistance: 2)
                    .onChanged { drag in
                        if abs(drag.translation.height) < 2 { dragStartIndex = currentIndex }
                        let delta = Int(-drag.translation.height / 25)
                        let newIndex = min(values.count - 1, max(0, dragStartIndex + delta))
                        value = values[newIndex]
                    }
                    .onEnded { _ in
                        dragStartIndex = currentIndex
                    }
            )

            // Clickable value — opens dropdown
            Button(action: { showDropdown.toggle() }) {
                Text(formatRate(value))
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.07))
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                            )
                    )
            }
            .buttonStyle(.plain)
            .popover(isPresented: $showDropdown) {
                VStack(spacing: 0) {
                    ForEach(values, id: \.self) { rate in
                        Button(action: { value = rate; showDropdown = false }) {
                            HStack {
                                Text(formatRate(rate))
                                    .font(.system(size: 13, design: .monospaced))
                                Spacer()
                                if rate == value {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.blue)
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        if rate != values.last { Divider() }
                    }
                }
                .frame(width: 140)
                .padding(.vertical, 4)
            }
        }
    }

    private func formatRate(_ rate: Int) -> String {
        let thousands = rate / 1000
        let remainder = (rate % 1000) / 100
        if remainder == 0 { return "\(thousands)k" }
        return "\(thousands).\(remainder)k"
    }

    private func formatRateShort(_ rate: Int) -> String {
        let thousands = rate / 1000
        let remainder = (rate % 1000) / 100
        if remainder == 0 { return "\(thousands)" }
        return "\(thousands).\(remainder)"
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
