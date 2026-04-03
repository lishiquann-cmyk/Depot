import Foundation

enum ScriptState: Equatable {
    case idle
    case loading            // process started, not yet ready
    case running            // dev: service ready (URL found)
    case completed          // build/deploy: finished successfully
    case failed(String)

    static func == (lhs: ScriptState, rhs: ScriptState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.loading, .loading), (.running, .running), (.completed, .completed):
            return true
        case (.failed(let a), .failed(let b)):
            return a == b
        default:
            return false
        }
    }

    var isActive: Bool { self == .loading || self == .running }

    var statusLabel: String {
        switch self {
        case .idle: "空闲"
        case .loading: "启动中..."
        case .running: "运行中"
        case .completed: "已完成"
        case .failed(let msg): "失败: \(msg)"
        }
    }
}

@Observable
final class Script: Identifiable {
    let id: String          // script key (e.g. "dev:admin")
    let command: String     // script value
    var categoryID: String  // matches Category.id
    var isDevStyle: Bool    // true = toggle+running UI; false = play button+completed UI

    var state: ScriptState = .idle
    var logs: [String] = []
    var extractedURL: URL?
    var extractedPath: String?
    var showLogs: Bool = false

    init(id: String, command: String, categoryID: String, isDevStyle: Bool) {
        self.id = id; self.command = command
        self.categoryID = categoryID; self.isDevStyle = isDevStyle
    }

    func reset() {
        logs = []; extractedURL = nil; extractedPath = nil
    }
}
