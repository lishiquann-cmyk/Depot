import SwiftUI

struct IconPickerView: View {
    @Binding var selectedIcon: String
    @Binding var selectedColor: String
    var onSelect: (() -> Void)? = nil

    @State private var searchText = ""

    private let sections: [(title: String, icons: [String])] = [
        ("开发", [
            "terminal.fill", "code", "hammer.fill", "wrench.and.screwdriver.fill",
            "gearshape.fill", "gearshape.2.fill", "cpu.fill", "memorychip.fill",
            "chevron.left.forwardslash.chevron.right", "curlybraces", "function",
            "swift", "laptopcomputer", "desktopcomputer", "macpro.gen3",
            "keyboard.fill", "computermouse.fill", "display", "externaldrive.fill",
            "internaldrive.fill", "sdcard.fill"
        ]),
        ("网络 & 云", [
            "network", "cloud.fill", "wifi", "wifi.router.fill",
            "antenna.radiowaves.left.and.right", "globe", "globe.americas.fill",
            "icloud.fill", "icloud.and.arrow.up.fill", "icloud.and.arrow.down.fill",
            "server.rack", "link", "paperplane.fill", "dot.radiowaves.left.and.right"
        ]),
        ("构建 & 部署", [
            "shippingbox.fill", "cube.fill", "cube.box.fill",
            "arrow.up.circle.fill", "arrow.down.circle.fill",
            "arrow.triangle.2.circlepath", "repeat", "clock.arrow.circlepath",
            "checkmark.seal.fill", "timer", "hourglass", "hourglass.bottomhalf.filled",
            "chart.bar.fill", "chart.line.uptrend.xyaxis", "gauge.with.dots.needle.bottom.50percent"
        ]),
        ("文件 & 数据", [
            "folder.fill", "folder.badge.plus", "tray.full.fill", "archivebox.fill",
            "doc.fill", "doc.text.fill", "doc.richtext.fill", "doc.badge.gearshape.fill",
            "tray.and.arrow.up.fill", "tray.and.arrow.down.fill",
            "externaldrive.badge.plus", "cylinder.fill", "cylinder.split.1x2.fill"
        ]),
        ("媒体", [
            "play.circle.fill", "play.rectangle.fill", "pause.circle.fill",
            "stop.circle.fill", "speaker.wave.3.fill", "mic.fill", "mic.circle.fill",
            "camera.fill", "photo.fill", "photo.stack.fill", "video.fill",
            "music.note", "music.note.list", "waveform", "waveform.circle.fill"
        ]),
        ("安全", [
            "lock.fill", "lock.open.fill", "shield.fill", "shield.lefthalf.filled",
            "checkmark.shield.fill", "key.fill", "key.horizontal.fill",
            "eye.fill", "eye.slash.fill", "hand.raised.fill",
            "exclamationmark.triangle.fill", "exclamationmark.shield.fill",
            "person.fill", "person.crop.circle.fill", "person.2.fill"
        ]),
        ("界面 & 设计", [
            "star.fill", "heart.fill", "wand.and.stars", "wand.and.rays",
            "sparkles", "paintbrush.fill", "paintpalette.fill",
            "pencil", "pencil.circle.fill", "scissors", "scissors.circle.fill",
            "magnifyingglass", "magnifyingglass.circle.fill",
            "hand.thumbsup.fill", "hand.thumbsdown.fill",
            "square.and.pencil", "rectangle.and.pencil.and.ellipsis"
        ]),
        ("通知 & 标签", [
            "bell.fill", "bell.badge.fill", "tag.fill", "tag.circle.fill",
            "flag.fill", "flag.checkered", "bookmark.fill", "bookmark.circle.fill",
            "pin.fill", "pin.circle.fill", "mappin.circle.fill",
            "bubble.left.fill", "bubble.right.fill", "quote.bubble.fill"
        ]),
        ("位置 & 导航", [
            "map.fill", "location.fill", "location.circle.fill",
            "arrow.up.circle.fill", "arrow.right.circle.fill",
            "house.fill", "building.2.fill", "building.columns.fill",
            "signpost.right.fill", "road.lanes", "airplane", "car.fill"
        ]),
        ("自然 & 其他", [
            "leaf.fill", "drop.fill", "flame.fill", "snowflake",
            "sun.max.fill", "moon.fill", "cloud.rain.fill", "wind",
            "lightbulb.fill", "bolt.fill", "ant.fill", "hare.fill",
            "tortoise.fill", "bird.fill", "fish.fill", "pawprint.fill"
        ])
    ]

    private var filteredSections: [(title: String, icons: [String])] {
        guard !searchText.isEmpty else { return sections }
        let q = searchText.lowercased()
        let flat = sections.flatMap(\.icons).filter { $0.lowercased().contains(q) }
        return flat.isEmpty ? [] : [("结果", flat)]
    }

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
    private let selectedColor2 = Category.availableColors   // shorthand

    var body: some View {
        VStack(spacing: 0) {
            // Search
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass").foregroundStyle(.secondary).font(.caption)
                TextField("搜索图标", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.callout)
                if !searchText.isEmpty {
                    Button { searchText = "" } label: {
                        Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(.bar)

            Divider()

            // Color palette
            colorPalette

            Divider()

            // Icon grid
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 10) {
                    ForEach(filteredSections, id: \.title) { section in
                        if filteredSections.count > 1 {
                            Text(section.title)
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 10)
                                .padding(.top, 6)
                        }
                        LazyVGrid(columns: columns, spacing: 4) {
                            ForEach(section.icons, id: \.self) { icon in
                                iconCell(icon)
                            }
                        }
                        .padding(.horizontal, 6)
                    }
                    if filteredSections.isEmpty {
                        Text("无匹配图标").font(.caption).foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity).padding()
                    }
                }
                .padding(.bottom, 8)
            }
        }
        .frame(width: 260, height: 360)
    }

    private var colorPalette: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(Category.availableColors, id: \.name) { item in
                    Circle()
                        .fill(item.color)
                        .frame(width: 22, height: 22)
                        .overlay(
                            Circle().stroke(Color.primary.opacity(selectedColor == item.name ? 0.8 : 0), lineWidth: 2)
                                .padding(2)
                        )
                        .overlay(
                            Image(systemName: "checkmark")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.white)
                                .opacity(selectedColor == item.name ? 1 : 0)
                        )
                        .onTapGesture { selectedColor = item.name }
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
        }
        .background(.bar)
    }

    private func iconCell(_ icon: String) -> some View {
        let isSelected = selectedIcon == icon
        let color = Category.swiftUIColor(selectedColor)
        return Button {
            selectedIcon = icon
            onSelect?()
        } label: {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(isSelected ? .white : color)
                .frame(width: 32, height: 32)
                .background(isSelected ? color : color.opacity(0.1),
                            in: RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
        .help(icon)
    }
}
