import Foundation

/// Per-project configuration: custom categories + log-extract rules.
struct ProjectConfig: Codable {
    var categories: [CategoryData]
    var extractRules: [LogExtractRule]

    static let `default` = ProjectConfig(
        categories: [CategoryData.defaultDev],
        extractRules: []
    )
}

enum ProjectConfigStore {
    private static func dir() -> URL {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let dir = support.appendingPathComponent("dev-status-board/configs")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    static func load(projectID: UUID) -> ProjectConfig {
        let url = dir().appendingPathComponent("\(projectID.uuidString).json")
        guard let data = try? Data(contentsOf: url),
              let config = try? JSONDecoder().decode(ProjectConfig.self, from: data)
        else { return .default }
        return config
    }

    static func save(_ config: ProjectConfig, projectID: UUID) {
        let encoder = JSONEncoder(); encoder.outputFormatting = .prettyPrinted
        guard let data = try? encoder.encode(config) else { return }
        try? data.write(to: dir().appendingPathComponent("\(projectID.uuidString).json"), options: .atomic)
    }
}
