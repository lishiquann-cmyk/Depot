import Foundation
import SwiftUI

enum ExtractType: String, Codable, CaseIterable {
    case url, folder

    var label: String {
        switch self {
        case .url: "URL"
        case .folder: "目录"
        }
    }

    var tagColor: Color {
        switch self {
        case .url: .green
        case .folder: .blue
        }
    }
}

struct LogExtractRule: Codable, Identifiable {
    var id: UUID
    var name: String
    var type: ExtractType
    var prefix: String   // log lines starting with this prefix are matched
    var order: Int

    init(id: UUID = UUID(), name: String, type: ExtractType, prefix: String, order: Int = 0) {
        self.id = id; self.name = name; self.type = type
        self.prefix = prefix; self.order = order
    }
}
