import SwiftUI

/// Seven-segment digit display — authentic digital clock look.
struct SevenSegmentDisplay: View {
    let text: String
    let digitHeight: CGFloat
    let color: Color

    init(_ text: String, height: CGFloat = 32, color: Color = .green) {
        self.text = text
        self.digitHeight = height
        self.color = color
    }

    var body: some View {
        HStack(spacing: digitHeight * 0.12) {
            ForEach(Array(text.enumerated()), id: \.offset) { _, char in
                if char == "." {
                    Circle()
                        .fill(color)
                        .shadow(color: color.opacity(0.8), radius: 3)
                        .frame(width: digitHeight * 0.12, height: digitHeight * 0.12)
                        .offset(y: digitHeight * 0.44)
                } else if let digit = Int(String(char)) {
                    SevenSegmentDigit(digit: digit, height: digitHeight, color: color)
                }
            }
        }
    }
}

/// Draws a single seven-segment digit.
struct SevenSegmentDigit: View {
    let digit: Int
    let height: CGFloat
    let color: Color

    // Segment map: which segments are ON for each digit
    // Segments: a(top) b(top-right) c(bottom-right) d(bottom) e(bottom-left) f(top-left) g(middle)
    private static let segmentMap: [[Bool]] = [
        [true, true, true, true, true, true, false],    // 0
        [false, true, true, false, false, false, false], // 1
        [true, true, false, true, true, false, true],    // 2
        [true, true, true, true, false, false, true],    // 3
        [false, true, true, false, false, true, true],   // 4
        [true, false, true, true, false, true, true],    // 5
        [true, false, true, true, true, true, true],     // 6
        [true, true, true, false, false, false, false],  // 7
        [true, true, true, true, true, true, true],      // 8
        [true, true, true, true, false, true, true],     // 9
    ]

    private var segments: [Bool] {
        guard digit >= 0, digit <= 9 else { return Array(repeating: false, count: 7) }
        return Self.segmentMap[digit]
    }

    private var w: CGFloat { height * 0.55 }
    private var segW: CGFloat { w * 0.8 }  // horizontal segment width
    private var segH: CGFloat { height * 0.1 } // segment thickness
    private var halfH: CGFloat { height * 0.46 }

    var body: some View {
        ZStack {
            // a - top horizontal
            segment(on: segments[0])
                .frame(width: segW, height: segH)
                .offset(y: -halfH)

            // d - bottom horizontal
            segment(on: segments[3])
                .frame(width: segW, height: segH)
                .offset(y: halfH)

            // g - middle horizontal
            segment(on: segments[6])
                .frame(width: segW, height: segH)

            // b - top right vertical
            segment(on: segments[1])
                .frame(width: segH, height: halfH * 0.85)
                .offset(x: segW * 0.45, y: -halfH * 0.48)

            // c - bottom right vertical
            segment(on: segments[2])
                .frame(width: segH, height: halfH * 0.85)
                .offset(x: segW * 0.45, y: halfH * 0.48)

            // e - bottom left vertical
            segment(on: segments[4])
                .frame(width: segH, height: halfH * 0.85)
                .offset(x: -segW * 0.45, y: halfH * 0.48)

            // f - top left vertical
            segment(on: segments[5])
                .frame(width: segH, height: halfH * 0.85)
                .offset(x: -segW * 0.45, y: -halfH * 0.48)
        }
        .frame(width: w, height: height)
    }

    @ViewBuilder
    private func segment(on: Bool) -> some View {
        RoundedRectangle(cornerRadius: 1)
            .fill(on ? color : color.opacity(0.06))
            .shadow(color: on ? color.opacity(0.7) : .clear, radius: on ? 4 : 0)
    }
}
