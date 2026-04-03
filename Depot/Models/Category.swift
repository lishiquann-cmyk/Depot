import Foundation
import SwiftUI

// MARK: - Color helpers

extension Category {
    static let availableColors: [(name: String, color: Color)] = [
        ("red", .red), ("orange", .orange), ("yellow", .yellow), ("green", .green),
        ("mint", .mint), ("teal", .teal), ("cyan", .cyan), ("blue", .blue),
        ("indigo", .indigo), ("purple", .purple), ("pink", .pink), ("brown", .brown),
        ("gray", .gray)
    ]

    static func swiftUIColor(_ name: String) -> Color {
        availableColors.first(where: { $0.name == name })?.color ?? .accentColor
    }
}

// MARK: - Codable snapshot for persistence

struct CategoryData: Identifiable {
    var id: String
    var name: String
    var icon: String
    var iconColor: String   // color name, e.g. "green", "blue"
    var keyPrefix: String
    var isDevCategory: Bool
    var order: Int

    init(id: String, name: String, icon: String, iconColor: String = "blue",
         keyPrefix: String, isDevCategory: Bool, order: Int) {
        self.id = id; self.name = name; self.icon = icon; self.iconColor = iconColor
        self.keyPrefix = keyPrefix; self.isDevCategory = isDevCategory; self.order = order
    }

    static let defaultDev = CategoryData(
        id: "dev", name: "Dev", icon: "chevron.left.forwardslash.chevron.right", iconColor: "green",
        keyPrefix: "dev", isDevCategory: true, order: 0
    )
}

extension CategoryData: Codable {
    enum CodingKeys: String, CodingKey {
        case id, name, icon, iconColor, keyPrefix, isDevCategory, order
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        icon = try c.decode(String.self, forKey: .icon)
        iconColor = try c.decodeIfPresent(String.self, forKey: .iconColor) ?? "blue"
        keyPrefix = try c.decode(String.self, forKey: .keyPrefix)
        isDevCategory = try c.decode(Bool.self, forKey: .isDevCategory)
        order = try c.decode(Int.self, forKey: .order)
    }
}

// MARK: - Observable runtime model

@Observable
final class Category: Identifiable, Hashable {
    var id: String
    var name: String
    var icon: String
    var iconColor: String
    var keyPrefix: String
    var isDevCategory: Bool
    var order: Int

    init(_ data: CategoryData) {
        id = data.id; name = data.name; icon = data.icon; iconColor = data.iconColor
        keyPrefix = data.keyPrefix; isDevCategory = data.isDevCategory; order = data.order
    }

    var data: CategoryData {
        CategoryData(id: id, name: name, icon: icon, iconColor: iconColor,
                     keyPrefix: keyPrefix, isDevCategory: isDevCategory, order: order)
    }

    func matches(scriptKey: String) -> Bool {
        scriptKey == keyPrefix || scriptKey.hasPrefix(keyPrefix + ":")
    }

    var accentColor: Color { Category.swiftUIColor(iconColor) }

    static func == (lhs: Category, rhs: Category) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
