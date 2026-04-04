import Foundation
import AppKit

@Observable
final class AppViewModel {

    // MARK: - Projects
    var projects: [ProjectEntry] = []
    var currentProject: ProjectEntry? = nil

    // MARK: - Per-project config (categories + extract rules)
    var categories: [Category] = []
    var extractRules: [LogExtractRule] = []

    // MARK: - Runtime script state
    var scripts: [Script] = []
    var loadError: String? = nil
    var packageManager: String = "pnpm"

    private var processes: [String: Process] = [:]

    // MARK: - Computed

    var sortedCategories: [Category] { categories.sorted { $0.order < $1.order } }

    func scripts(for category: Category) -> [Script] {
        scripts.filter { $0.categoryID == category.id }
    }

    // MARK: - Init

    init() {
        let list = ProjectListStore.load()
        projects = list.projects

        if let lastID = list.lastProjectID,
           let project = projects.first(where: { $0.id == lastID }),
           FileManager.default.fileExists(atPath: project.packageJSONPath) {
            internalLoadProject(project)
        }
    }

    // MARK: - Project Management

    func addProject(from url: URL) {
        // Prefer "name" field from package.json; fall back to directory name
        let name: String
        if let data = try? Data(contentsOf: url),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let pkgName = json["name"] as? String, !pkgName.isEmpty {
            name = pkgName
        } else {
            name = url.deletingLastPathComponent().lastPathComponent
        }
        let project = ProjectEntry(name: name, packageJSONPath: url.path)
        projects.append(project)
        saveProjectList(lastProjectID: project.id)
        internalLoadProject(project)
    }

    func selectProject(_ project: ProjectEntry) {
        guard FileManager.default.fileExists(atPath: project.packageJSONPath) else {
            loadError = "package.json 不存在：\(project.packageJSONPath)"
            return
        }
        saveScriptStates()
        saveProjectList(lastProjectID: project.id)
        internalLoadProject(project)
    }

    func removeProject(id: UUID) {
        if currentProject?.id == id {
            stopAllScripts()
            currentProject = nil
            categories = []; extractRules = []; scripts = []
        }
        projects.removeAll { $0.id == id }
        saveProjectList(lastProjectID: currentProject?.id)
    }

    func backToProjectList() {
        saveScriptStates()
        currentProject = nil
    }

    private func internalLoadProject(_ project: ProjectEntry) {
        stopAllScripts()
        let config = ProjectConfigStore.load(projectID: project.id)
        categories = config.categories.sorted { $0.order < $1.order }.map { Category($0) }
        extractRules = config.extractRules.sorted { $0.order < $1.order }
        currentProject = project
        loadError = nil

        do {
            let parsed = try parsePackageJSON(
                at: URL(fileURLWithPath: project.packageJSONPath),
                categories: categories
            )
            scripts = parsed.scripts
            packageManager = parsed.packageManager
            restoreScriptStates(projectID: project.id)
        } catch {
            loadError = error.localizedDescription
        }
    }

    var activeScriptCount: Int { scripts.filter { $0.state.isActive }.count }

    func stopAllScripts() {
        for script in scripts where script.state.isActive { stopScript(script) }
    }

    // MARK: - Category Management

    func addCategory(name: String, icon: String, colorName: String) {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        let prefix = trimmed.lowercased()
        guard !prefix.isEmpty else { return }
        // Case-insensitive duplicate check
        guard !categories.contains(where: { $0.name.lowercased() == prefix }) else { return }
        let nextOrder = (sortedCategories.last?.order ?? -1) + 1
        let id = prefix + "-" + String(UUID().uuidString.prefix(6))
        let data = CategoryData(id: id, name: trimmed, icon: icon, iconColor: colorName,
                                keyPrefix: prefix, isDevCategory: false, order: nextOrder)
        categories.append(Category(data))
        refreshScripts()
        saveProjectConfig()
    }

    func updateCategory(id: String, name: String, icon: String, colorName: String) {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard let cat = categories.first(where: { $0.id == id }) else { return }
        // Duplicate check: ignore the category being edited itself
        let conflict = categories.contains {
            $0.id != id && $0.name.lowercased() == trimmed.lowercased()
        }
        guard !conflict else { return }
        cat.name = trimmed
        cat.icon = icon
        cat.iconColor = colorName
        if !cat.isDevCategory {
            cat.keyPrefix = trimmed.lowercased()
        }
        refreshScripts()
        saveProjectConfig()
    }

    func deleteCategory(id: String) {
        categories.removeAll { $0.id == id }
        scripts.removeAll { $0.categoryID == id }
        reindexCategoryOrders()
        saveProjectConfig()
    }

    func moveCategoryUp(id: String) {
        var sorted = sortedCategories
        guard let idx = sorted.firstIndex(where: { $0.id == id }), idx > 0 else { return }
        sorted.swapAt(idx, idx - 1)
        for (i, cat) in sorted.enumerated() { cat.order = i }
        saveProjectConfig()
    }

    func moveCategoryDown(id: String) {
        var sorted = sortedCategories
        guard let idx = sorted.firstIndex(where: { $0.id == id }),
              idx < sorted.count - 1 else { return }
        sorted.swapAt(idx, idx + 1)
        for (i, cat) in sorted.enumerated() { cat.order = i }
        saveProjectConfig()
    }

    private func reindexCategoryOrders() {
        let sorted = sortedCategories
        for (i, cat) in sorted.enumerated() { cat.order = i }
    }

    private func refreshScripts() {
        guard let project = currentProject else { return }
        // Snapshot current runtime state
        let states = Dictionary(uniqueKeysWithValues: scripts.map { ($0.id, $0.state) })
        let logs   = Dictionary(uniqueKeysWithValues: scripts.map { ($0.id, $0.logs) })
        let urls   = Dictionary(uniqueKeysWithValues: scripts.map { ($0.id, $0.extractedURL) })
        let paths  = Dictionary(uniqueKeysWithValues: scripts.map { ($0.id, $0.extractedPath) })

        guard let parsed = try? parsePackageJSON(
            at: URL(fileURLWithPath: project.packageJSONPath),
            categories: categories
        ) else { return }

        scripts = parsed.scripts
        packageManager = parsed.packageManager
        for s in scripts {
            if let st = states[s.id] { s.state = st }
            if let lg = logs[s.id]   { s.logs = lg }
            if let u  = urls[s.id]   { s.extractedURL = u }
            if let p  = paths[s.id]  { s.extractedPath = p }
        }
    }

    // MARK: - Extract Rule Management

    func addExtractRule(_ rule: LogExtractRule) {
        var r = rule
        r.order = (extractRules.max(by: { $0.order < $1.order })?.order ?? -1) + 1
        extractRules.append(r)
        saveProjectConfig()
    }

    func updateExtractRule(_ rule: LogExtractRule) {
        if let i = extractRules.firstIndex(where: { $0.id == rule.id }) {
            extractRules[i] = rule
            saveProjectConfig()
        }
    }

    func deleteExtractRule(id: UUID) {
        extractRules.removeAll { $0.id == id }
        for (i, _) in extractRules.enumerated() { extractRules[i].order = i }
        saveProjectConfig()
    }

    func moveExtractRuleUp(id: UUID) {
        guard let idx = extractRules.firstIndex(where: { $0.id == id }), idx > 0 else { return }
        extractRules.swapAt(idx, idx - 1)
        for (i, _) in extractRules.enumerated() { extractRules[i].order = i }
        saveProjectConfig()
    }

    func moveExtractRuleDown(id: UUID) {
        guard let idx = extractRules.firstIndex(where: { $0.id == id }),
              idx < extractRules.count - 1 else { return }
        extractRules.swapAt(idx, idx + 1)
        for (i, _) in extractRules.enumerated() { extractRules[i].order = i }
        saveProjectConfig()
    }

    // MARK: - Script Lifecycle

    func startScript(_ script: Script) {
        guard let project = currentProject else { return }
        let workingDir = URL(fileURLWithPath: project.packageJSONPath).deletingLastPathComponent()

        script.reset()
        script.state = .loading

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-l", "-c", "\(packageManager) run '\(script.id)'"]
        process.currentDirectoryURL = workingDir
        process.environment = buildEnvironment()

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        let fileHandle = pipe.fileHandleForReading

        fileHandle.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            if data.isEmpty { handle.readabilityHandler = nil; return }
            guard let text = String(data: data, encoding: .utf8) else { return }
            let lines = text
                .components(separatedBy: "\n")
                .map { AppViewModel.stripANSI($0).trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
            Task { @MainActor [weak self] in
                guard let self else { return }
                for line in lines {
                    script.logs.append(line)
                    self.parseOutput(line, for: script)
                }
            }
        }

        process.terminationHandler = { [weak self] proc in
            let code = proc.terminationStatus
            Task { @MainActor [weak self] in
                guard let self else { return }
                fileHandle.readabilityHandler = nil
                self.processes.removeValue(forKey: script.id)
                guard script.state != .idle else { return }
                script.state = script.isDevStyle
                    ? .idle
                    : (code == 0 ? .completed : .failed("Exit \(code)"))
                self.saveScriptStates()
            }
        }

        do {
            try process.run()
            processes[script.id] = process
        } catch {
            script.state = .failed(error.localizedDescription)
        }
    }

    /// Immediately kills the process (SIGINT + SIGTERM).
    func stopScript(_ script: Script) {
        if let process = processes[script.id] {
            process.interrupt()
            process.terminate()
            processes.removeValue(forKey: script.id)
        } else if script.isDevStyle, let port = script.extractedURL?.port {
            Task.detached { killProcessOnPort(port) }
        }
        script.state = .idle
        saveScriptStates()
    }

    func openURL(_ url: URL) {
        NSWorkspace.shared.open(url)
    }

    func openFolder(_ path: String) {
        guard let project = currentProject else { return }
        let workDir = URL(fileURLWithPath: project.packageJSONPath).deletingLastPathComponent().path
        let full = path.hasPrefix("/") ? path : (workDir + "/" + path)
        let url = URL(fileURLWithPath: full)
        var isDir: ObjCBool = false
        if FileManager.default.fileExists(atPath: full, isDirectory: &isDir) {
            if isDir.boolValue {
                NSWorkspace.shared.open(url)
            } else {
                NSWorkspace.shared.activateFileViewerSelecting([url])
            }
        } else {
            NSWorkspace.shared.open(URL(fileURLWithPath: full).deletingLastPathComponent())
        }
    }

    // MARK: - Output Parsing

    private func parseOutput(_ line: String, for script: Script) {
        // Custom rules (ordered by .order)
        for rule in extractRules.sorted(by: { $0.order < $1.order }) {
            if line.hasPrefix(rule.prefix) {
                let value = String(line.dropFirst(rule.prefix.count))
                    .trimmingCharacters(in: .whitespaces)
                switch rule.type {
                case .url:
                    if let url = URL(string: value) {
                        script.extractedURL = url
                        if script.isDevStyle { script.state = .running; saveScriptStates() }
                    }
                case .folder:
                    script.extractedPath = value
                }
                return
            }
        }

        // Fallback: find any http/https URL in the line, no restrictions
        if script.extractedURL == nil,
           let urlStr = firstMatch(in: line, pattern: #"https?://\S+"#) {
            let cleaned = urlStr.trimmingCharacters(in: CharacterSet(charactersIn: ".,;:\"')>"))
            if let url = URL(string: cleaned) {
                script.extractedURL = url
                if script.isDevStyle { script.state = .running; saveScriptStates() }
            }
        }
    }

    private func firstMatch(in text: String, pattern: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(text.startIndex..., in: text)
        guard let match = regex.firstMatch(in: text, range: range),
              let sr = Range(match.range, in: text) else { return nil }
        return String(text[sr])
    }

    // MARK: - Persistence

    func saveProjectConfig() {
        guard let project = currentProject else { return }
        let config = ProjectConfig(
            categories: sortedCategories.map { $0.data },
            extractRules: extractRules.sorted { $0.order < $1.order }
        )
        ProjectConfigStore.save(config, projectID: project.id)
    }

    func saveScriptStates() {
        guard let project = currentProject else { return }
        var states: [String: PersistedScriptState] = [:]
        for s in scripts {
            let savedState: String
            switch s.state {
            case .running:   savedState = "running"
            case .completed: savedState = "completed"
            default:         savedState = "idle"
            }
            states[s.id] = PersistedScriptState(
                savedState: savedState,
                extractedURL: s.extractedURL?.absoluteString,
                extractedPath: s.extractedPath,
                logs: Array(s.logs.suffix(500))
            )
        }
        ScriptStateStore.save(
            PersistedProjectScriptStates(scriptStates: states),
            projectID: project.id
        )
    }

    private func restoreScriptStates(projectID: UUID) {
        guard let saved = ScriptStateStore.load(projectID: projectID) else { return }
        for script in scripts {
            guard let ss = saved.scriptStates[script.id] else { continue }
            if !ss.logs.isEmpty { script.logs = ss.logs }
            switch ss.savedState {
            case "running" where script.isDevStyle:
                if let urlStr = ss.extractedURL, let url = URL(string: urlStr),
                   let port = url.port, isPortListening(port) {
                    script.extractedURL = url
                    script.state = .running
                }
            case "completed":
                script.extractedURL = ss.extractedURL.flatMap { URL(string: $0) }
                script.extractedPath = ss.extractedPath
                script.state = .completed
            default: break
            }
        }
    }

    private func saveProjectList(lastProjectID: UUID?) {
        ProjectListStore.save(ProjectList(projects: projects, lastProjectID: lastProjectID))
    }

    // MARK: - Helpers

    private func buildEnvironment() -> [String: String] {
        var env = ProcessInfo.processInfo.environment
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let extras = ["/usr/local/bin", "/opt/homebrew/bin", "/opt/homebrew/sbin",
                      "\(home)/.local/bin", "\(home)/.local/share/pnpm",
                      "\(home)/.npm/bin", "\(home)/.npm-global/bin",
                      "\(home)/.volta/bin", "\(home)/.nvm/bin",
                      "\(home)/.bun/bin"].joined(separator: ":")
        env["PATH"] = "\(extras):\(env["PATH"] ?? "/usr/bin:/bin")"
        env["FORCE_COLOR"] = "0"; env["NO_COLOR"] = "1"
        return env
    }

    static func stripANSI(_ text: String) -> String {
        guard let regex = try? NSRegularExpression(
            pattern: #"\x1B(?:[@-Z\\-_]|\[[0-?]*[ -/]*[@-~])"#
        ) else { return text }
        return regex.stringByReplacingMatches(
            in: text, range: NSRange(text.startIndex..., in: text), withTemplate: "")
    }
}
