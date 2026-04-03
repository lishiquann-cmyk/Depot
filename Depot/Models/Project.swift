import Foundation

struct ProjectEntry: Codable, Identifiable, Hashable {
    var id: UUID
    var name: String
    var packageJSONPath: String

    init(id: UUID = UUID(), name: String, packageJSONPath: String) {
        self.id = id; self.name = name; self.packageJSONPath = packageJSONPath
    }
}
