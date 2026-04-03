import Foundation

struct ProjectList: Codable {
    var projects: [ProjectEntry]
    var lastProjectID: UUID?
}

enum ProjectListStore {
    private static var fileURL: URL {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let dir = support.appendingPathComponent("dev-status-board")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("projectlist.json")
    }

    static func load() -> ProjectList {
        guard let data = try? Data(contentsOf: fileURL),
              let list = try? JSONDecoder().decode(ProjectList.self, from: data)
        else { return ProjectList(projects: [], lastProjectID: nil) }
        return list
    }

    static func save(_ list: ProjectList) {
        let encoder = JSONEncoder(); encoder.outputFormatting = .prettyPrinted
        guard let data = try? encoder.encode(list) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
