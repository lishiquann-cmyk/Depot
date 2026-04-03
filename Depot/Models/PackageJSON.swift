import Foundation

private struct PackageJSONRaw: Decodable {
    let scripts: [String: String]?
    let packageManager: String?
    let name: String?
}

struct ParsedPackage {
    let scripts: [Script]
    let packageManager: String
    let projectName: String?
}

func parsePackageJSON(at url: URL, categories: [Category]) throws -> ParsedPackage {
    let data = try Data(contentsOf: url)
    let raw = try JSONDecoder().decode(PackageJSONRaw.self, from: data)

    // Detect package manager from the "packageManager" field (e.g. "pnpm@8.0.0" → "pnpm")
    let pm: String
    if let pmStr = raw.packageManager,
       let detected = pmStr.split(separator: "@").first.map(String.init),
       !detected.isEmpty {
        pm = detected.lowercased()
    } else {
        pm = "pnpm"
    }

    let allScripts = raw.scripts ?? [:]
    let scripts: [Script] = allScripts.compactMap { key, command in
        guard let category = categories.first(where: { $0.matches(scriptKey: key) }) else {
            return nil
        }
        return Script(id: key, command: command, categoryID: category.id,
                      isDevStyle: category.isDevCategory)
    }.sorted { $0.id < $1.id }

    return ParsedPackage(scripts: scripts, packageManager: pm, projectName: raw.name)
}
