import Foundation

// MARK: - Persisted Script State

struct PersistedScriptState: Codable {
    var savedState: String      // "running" | "completed" | "idle"
    var extractedURL: String?
    var extractedPath: String?
    var logs: [String]
}

struct PersistedProjectScriptStates: Codable {
    var scriptStates: [String: PersistedScriptState]
}

// MARK: - Port Utilities

/// Returns true if a TCP process is listening on the given port.
func isPortListening(_ port: Int) -> Bool {
    let task = Process()
    task.executableURL = URL(filePath: "/usr/sbin/lsof")
    task.arguments = ["-i", ":\(port)", "-sTCP:LISTEN", "-n", "-P"]
    let pipe = Pipe()
    task.standardOutput = pipe
    task.standardError = Pipe()
    try? task.run()
    task.waitUntilExit()
    return !pipe.fileHandleForReading.readDataToEndOfFile().isEmpty
}

/// Sends SIGTERM to all processes listening on the given port.
func killProcessOnPort(_ port: Int) {
    let task = Process()
    task.executableURL = URL(filePath: "/bin/bash")
    task.arguments = ["-c", "lsof -ti :\(port) | xargs kill -TERM 2>/dev/null; true"]
    task.standardOutput = Pipe()
    task.standardError = Pipe()
    try? task.run()
    task.waitUntilExit()
}

// MARK: - Script State Storage (per-project)

enum ScriptStateStore {
    private static func dir() -> URL {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let dir = support.appendingPathComponent("dev-status-board/states")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    static func save(_ states: PersistedProjectScriptStates, projectID: UUID) {
        let encoder = JSONEncoder(); encoder.outputFormatting = .prettyPrinted
        guard let data = try? encoder.encode(states) else { return }
        try? data.write(to: dir().appendingPathComponent("\(projectID.uuidString).json"), options: .atomic)
    }

    static func load(projectID: UUID) -> PersistedProjectScriptStates? {
        let url = dir().appendingPathComponent("\(projectID.uuidString).json")
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(PersistedProjectScriptStates.self, from: data)
    }
}
