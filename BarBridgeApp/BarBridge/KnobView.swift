import SwiftUI

/// Rotary knob control with arc indicator — pure SwiftUI, no images.
struct KnobView: View {
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let displayFormat: (Double) -> String

    @State private var dragStartValue: Double = 0

    // Knob arc runs from 225° (min) to -45° (max) = 270° sweep
    private let startAngle: Double = 225
    private let totalSweep: Double = 270

    private var normalizedValue: Double {
        (value - range.lowerBound) / (range.upperBound - range.lowerBound)
    }

    private var pointerAngle: Angle {
        .degrees(startAngle - normalizedValue * totalSweep)
    }

    var body: some View {
        VStack(spacing: 6) {
            Text(label)
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(.gray)
                .textCase(.uppercase)

            ZStack {
                // Track arc (dark)
                Arc(startAngle: .degrees(-startAngle), endAngle: .degrees(-startAngle + totalSweep), clockwise: false)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 3)
                    .frame(width: 52, height: 52)

                // Value arc (blue/purple)
                Arc(startAngle: .degrees(-startAngle), endAngle: .degrees(-startAngle + normalizedValue * totalSweep), clockwise: false)
                    .stroke(
                        LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing),
                        lineWidth: 3
                    )
                    .frame(width: 52, height: 52)

                // Tick marks
                ForEach(0..<11) { i in
                    let tickAngle = startAngle - Double(i) / 10.0 * totalSweep
                    Rectangle()
                        .fill(Color.gray.opacity(0.4))
                        .frame(width: 1, height: 4)
                        .offset(y: -30)
                        .rotationEffect(.degrees(-tickAngle))
                }

                // Knob body
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color(white: 0.35), Color(white: 0.15)],
                            center: .topLeading,
                            startRadius: 0,
                            endRadius: 30
                        )
                    )
                    .frame(width: 40, height: 40)
                    .shadow(color: .black.opacity(0.5), radius: 3, y: 2)

                // Pointer
                Capsule()
                    .fill(Color.white.opacity(0.9))
                    .frame(width: 2, height: 12)
                    .offset(y: -11)
                    .rotationEffect(pointerAngle)
            }
            .frame(width: 64, height: 64)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { drag in
                        if dragStartValue == 0 && drag.translation.height == 0 {
                            dragStartValue = value
                        }
                        let delta = -drag.translation.height / 150.0
                        let span = range.upperBound - range.lowerBound
                        let newValue = dragStartValue + delta * span
                        value = min(range.upperBound, max(range.lowerBound, (newValue / step).rounded() * step))
                    }
                    .onEnded { _ in
                        dragStartValue = 0
                    }
            )

            // Value display
            Text(displayFormat(value))
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundColor(.white.opacity(0.8))
        }
    }
}

/// Integer version of KnobView for sample rates etc.
struct IntKnobView: View {
    let label: String
    @Binding var value: Int
    let values: [Int]

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
        VStack(spacing: 6) {
            Text(label)
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(.gray)
                .textCase(.uppercase)

            ZStack {
                Arc(startAngle: .degrees(-startAngle), endAngle: .degrees(-startAngle + totalSweep), clockwise: false)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 3)
                    .frame(width: 52, height: 52)

                Arc(startAngle: .degrees(-startAngle), endAngle: .degrees(-startAngle + normalizedValue * totalSweep), clockwise: false)
                    .stroke(
                        LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing),
                        lineWidth: 3
                    )
                    .frame(width: 52, height: 52)

                // Tick marks for each value
                ForEach(0..<values.count, id: \.self) { i in
                    let tickAngle = startAngle - Double(i) / Double(max(values.count - 1, 1)) * totalSweep
                    Rectangle()
                        .fill(Color.gray.opacity(0.5))
                        .frame(width: 1, height: 5)
                        .offset(y: -30)
                        .rotationEffect(.degrees(-tickAngle))
                }

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color(white: 0.35), Color(white: 0.15)],
                            center: .topLeading,
                            startRadius: 0,
                            endRadius: 30
                        )
                    )
                    .frame(width: 40, height: 40)
                    .shadow(color: .black.opacity(0.5), radius: 3, y: 2)

                Capsule()
                    .fill(Color.white.opacity(0.9))
                    .frame(width: 2, height: 12)
                    .offset(y: -11)
                    .rotationEffect(pointerAngle)
            }
            .frame(width: 64, height: 64)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { drag in
                        if drag.translation.height == 0 { dragStartIndex = currentIndex }
                        let delta = Int(-drag.translation.height / 40)
                        let newIndex = min(values.count - 1, max(0, dragStartIndex + delta))
                        value = values[newIndex]
                    }
                    .onEnded { _ in
                        dragStartIndex = currentIndex
                    }
            )

            Text("\(value)")
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundColor(.white.opacity(0.8))
        }
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
