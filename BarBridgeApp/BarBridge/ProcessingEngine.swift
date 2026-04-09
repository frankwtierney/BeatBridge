import SwiftUI
import Combine

class ProcessingEngine: ObservableObject {
    @Published var files: [ProcessedFile] = []
    @Published var ffmpegVersion: String? = nil

    // Path to the Python venv's python binary
    // Adjust this if your venv is elsewhere
    private var pythonPath: String {
        // Look for the venv in the BeatBridge project directory
        let candidates = [
            NSHomeDirectory() + "/Desktop/BeatBridge/venv/bin/python3",
            "/opt/homebrew/bin/python3.12",
            "/opt/homebrew/bin/python3",
            "/usr/local/bin/python3",
            "/usr/bin/python3",
        ]
        return candidates.first { FileManager.default.fileExists(atPath: $0) } ?? "python3"
    }

    private var barbridgeModule: String {
        // Path to the barbridge package
        let candidates = [
            NSHomeDirectory() + "/Desktop/BeatBridge",
        ]
        return candidates.first {
            FileManager.default.fileExists(atPath: $0 + "/barbridge/__main__.py")
        } ?? NSHomeDirectory() + "/Desktop/BeatBridge"
    }

    private let ffmpegPath: String = {
        let candidates = [
            "/opt/homebrew/bin/ffmpeg",
            "/usr/local/bin/ffmpeg",
            "/usr/bin/ffmpeg",
        ]
        return candidates.first { FileManager.default.fileExists(atPath: $0) } ?? "ffmpeg"
    }()

    func checkDependencies() {
        // Check FFmpeg using direct path
        let process = Process()
        process.executableURL = URL(fileURLWithPath: ffmpegPath)
        process.arguments = ["-version"]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
            process.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8),
               let firstLine = output.split(separator: "\n").first {
                let version = firstLine.split(separator: " ")
                    .first(where: { $0.contains(".") }) ?? "installed"
                DispatchQueue.main.async {
                    self.ffmpegVersion = "FFmpeg \(version)"
                }
            }
        } catch {
            DispatchQueue.main.async {
                self.ffmpegVersion = nil
            }
        }
    }

    func processFile(url: URL, config: SessionConfig) {
        // Add file to the list
        var file = ProcessedFile(inputPath: url)
        file.status = .processing(progress: 0.0)
        let fileIndex = files.count
        files.append(file)

        // Process in background
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.runPythonCLI(fileIndex: fileIndex, inputURL: url, config: config)
        }
    }

    private func runPythonCLI(fileIndex: Int, inputURL: URL, config: SessionConfig) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: pythonPath)
        process.currentDirectoryURL = URL(fileURLWithPath: barbridgeModule)
        process.arguments = [
            "-m", "barbridge",
            "--cli",
            inputURL.path,
            "--bpm", String(config.bpm),
            "--time-sig", "\(config.beatsPerBar)/\(config.beatValue)",
            "--start", String(config.startTimeSeconds),
            "--dest-sr", String(config.destinationSampleRate),
        ]

        // Add the project to PYTHONPATH and ensure Homebrew binaries are on PATH
        var env = ProcessInfo.processInfo.environment
        env["PYTHONPATH"] = barbridgeModule
        let existingPath = env["PATH"] ?? "/usr/bin:/bin"
        env["PATH"] = "/opt/homebrew/bin:/usr/local/bin:\(existingPath)"
        process.environment = env

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        DispatchQueue.main.async {
            if fileIndex < self.files.count {
                self.files[fileIndex].status = .processing(progress: 0.3)
            }
        }

        do {
            try process.run()
            process.waitUntilExit()

            let stdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
            let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
            let stdout = String(data: stdoutData, encoding: .utf8) ?? ""
            let stderr = String(data: stderrData, encoding: .utf8) ?? ""

            DispatchQueue.main.async {
                guard fileIndex < self.files.count else { return }

                if process.terminationStatus == 0 {
                    // Parse output path from CLI output
                    let outputPath = self.parseOutputPath(from: stdout)
                    self.files[fileIndex].outputPath = outputPath
                    self.files[fileIndex].summary = stdout
                    self.files[fileIndex].status = .complete
                } else {
                    let errorMsg = stderr.isEmpty ? "Processing failed (exit code \(process.terminationStatus))" : stderr.trimmingCharacters(in: .whitespacesAndNewlines)
                    self.files[fileIndex].status = .error(errorMsg)
                }
            }
        } catch {
            DispatchQueue.main.async {
                if fileIndex < self.files.count {
                    self.files[fileIndex].status = .error("Failed to launch Python: \(error.localizedDescription)")
                }
            }
        }
    }

    private func parseOutputPath(from output: String) -> URL? {
        // The CLI prints "Output file: /path/to/file"
        for line in output.split(separator: "\n") {
            if line.hasPrefix("Output file:") {
                let path = line.dropFirst("Output file:".count).trimmingCharacters(in: .whitespaces)
                return URL(fileURLWithPath: path)
            }
        }
        return nil
    }
}
