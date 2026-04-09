import SwiftUI
import Combine

// MARK: - Session Configuration

class SessionConfig: ObservableObject {
    @Published var bpm: Double = 120.0
    @Published var beatsPerBar: Int = 4
    @Published var beatValue: Int = 4
    @Published var destinationSampleRate: Int = 48000
    @Published var startTimeSeconds: Double = 0.0

    var timeSigLabel: String { "\(beatsPerBar)/\(beatValue)" }

    var barDuration: Double {
        (60.0 / bpm) * Double(beatsPerBar)
    }

    static let sampleRates = [44100, 48000, 88200, 96000]
    static let timeSignatures: [(Int, Int)] = [(3, 4), (4, 4), (5, 4), (6, 8), (7, 8)]
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
    var outputName: String { outputPath?.lastPathComponent ?? "—" }

    var isComplete: Bool {
        if case .complete = status { return true }
        return false
    }
}
