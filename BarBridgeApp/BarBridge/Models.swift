import SwiftUI
import Combine

// MARK: - Session Configuration

class SessionConfig: ObservableObject {
    @Published var bpm: Double = 120.0
    @Published var destinationSampleRate: Int = 48000
    @Published var barNumber: Int = 1
    @Published var beatNumber: Int = 1

    /// Bar position label for filenames: "M3B1" format
    var barPositionLabel: String { "M\(barNumber)B\(beatNumber)" }

    /// Display format for LED: "3.1"
    var barPositionDisplay: String { "\(barNumber).\(beatNumber)" }

    static let sampleRates = [44100, 48000, 88200, 96000]
}

// MARK: - Processed File

enum ProcessingStatus: Equatable {
    case queued
    case processing(progress: Double)
    case complete
    case error(String)
}

struct ProcessedFile: Identifiable {
    let id = UUID()
    let inputPath: URL
    var outputPath: URL?
    var status: ProcessingStatus = .queued
    var summary: String = ""

    var inputName: String { inputPath.lastPathComponent }
    var outputName: String { outputPath?.lastPathComponent ?? "" }

    var isComplete: Bool {
        if case .complete = status { return true }
        return false
    }

    var progress: Double {
        if case .processing(let p) = status { return p }
        if case .complete = status { return 1.0 }
        return 0.0
    }
}
