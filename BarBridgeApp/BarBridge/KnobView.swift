import SwiftUI

/// Rotary knob that snaps to fixed positions with click-to-dropdown.
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

    private var normalizedValue: Double {
        guard values.count > 1 else { return 0 }
        return Double(currentIndex) / Double(values.count - 1)
    }

    private var pointerAngle: Angle {
        .degrees(startAngle - normalizedValue * totalSweep)
    }

    var body: some View {
        VStack(spacing: 8) {
            RackLabel(text: label)

            ZStack {
                // Track arc
                Arc(startAngle: .degrees(-startAngle), endAngle: .degrees(-startAngle + totalSweep), clockwise: false)
                    .stroke(Color.gray.opacity(0.25), lineWidth: 3)
                    .frame(width: 60, height: 60)

                // Value arc
                Arc(startAngle: .degrees(-startAngle), endAngle: .degrees(-startAngle + normalizedValue * totalSweep), clockwise: false)
                    .stroke(
                        LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing),
                        lineWidth: 3
                    )
                    .frame(width: 60, height: 60)

                // Snap position tick marks
                ForEach(0..<values.count, id: \.self) { i in
                    let tickAngle = startAngle - Double(i) / Double(max(values.count - 1, 1)) * totalSweep
                    Rectangle()
                        .fill(i == currentIndex ? Color.blue : Color.gray.opacity(0.5))
                        .frame(width: 1.5, height: i == currentIndex ? 7 : 5)
                        .offset(y: -35)
                        .rotationEffect(.degrees(-tickAngle))
                }

                // Knob body
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color(white: 0.35), Color(white: 0.15)],
                            center: .topLeading,
                            startRadius: 0,
                            endRadius: 35
                        )
                    )
                    .frame(width: 48, height: 48)
                    .shadow(color: .black.opacity(0.5), radius: 4, y: 2)

                // Pointer
                Capsule()
                    .fill(Color.white.opacity(0.9))
                    .frame(width: 2.5, height: 14)
                    .offset(y: -13)
                    .rotationEffect(pointerAngle)
            }
            .frame(width: 76, height: 76)
            .gesture(
                DragGesture(minimumDistance: 2)
                    .onChanged { drag in
                        if drag.translation.height == 0 { dragStartIndex = currentIndex }
                        let delta = Int(-drag.translation.height / 30)
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
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.white.opacity(0.06))
                    )
            }
            .buttonStyle(.plain)
            .popover(isPresented: $showDropdown) {
                VStack(spacing: 0) {
                    ForEach(values, id: \.self) { rate in
                        Button(action: {
                            value = rate
                            showDropdown = false
                        }) {
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

                        if rate != values.last {
                            Divider()
                        }
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
        if remainder == 0 {
            return "\(thousands)k"
        }
        return "\(thousands).\(remainder)k"
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
