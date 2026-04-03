import SwiftUI
import AppKit
import UniformTypeIdentifiers

// MARK: - SidebarView

struct SidebarView: View {
    @Binding var selectedCategoryID: String?
    @Environment(AppViewModel.self) private var viewModel

    @State private var isAddingCategory = false
    @State private var editingCategoryID: String? = nil
    @State private var showProjectSwitcher = false
    @State private var showAddRuleDialog = false
    @State private var editingRule: LogExtractRule? = nil
    @State private var deleteConfirmCategoryID: String? = nil

    var body: some View {
        VStack(spacing: 0) {
            projectHeader
            Divider()
            categoryList
            Divider()
            rulesSection
        }
        .sheet(isPresented: $showAddRuleDialog) {
            AddExtractRuleView(
                isPresented: $showAddRuleDialog,
                ruleToEdit: editingRule
            ) { rule in
                if editingRule != nil {
                    viewModel.updateExtractRule(rule)
                } else {
                    viewModel.addExtractRule(rule)
                }
                editingRule = nil
            }
        }
    }

    // MARK: - Project Header

    private var projectHeader: some View {
        Button { showProjectSwitcher.toggle() } label: {
            HStack(spacing: 8) {
                Image(systemName: "shippingbox.fill")
                    .font(.callout).foregroundStyle(.secondary)
                VStack(alignment: .leading, spacing: 1) {
                    Text(viewModel.currentProject?.name ?? "未选择项目")
                        .font(.callout).fontWeight(.semibold)
                        .foregroundStyle(.primary).lineLimit(1)
                    Text("切换项目")
                        .font(.caption2).foregroundStyle(.tertiary)
                }
                Spacer()
                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption2).foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 12).padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .popover(isPresented: $showProjectSwitcher, arrowEdge: .bottom) {
            ProjectSwitcherPopover()
        }
    }

    // MARK: - Category List

    private var categoryList: some View {
        List(selection: $selectedCategoryID) {
            // Inline add form
            if isAddingCategory {
                CategoryFormRow(
                    initialName: "", initialIcon: "folder.fill", initialColor: "blue",
                    placeholder: "分类名称（即脚本前缀）",
                    onSave: { name, icon, color in
                        viewModel.addCategory(name: name, icon: icon, colorName: color)
                        selectedCategoryID = viewModel.sortedCategories.last?.id
                        isAddingCategory = false
                    },
                    onCancel: { isAddingCategory = false }
                )
            }

            // Category rows
            ForEach(viewModel.sortedCategories) { category in
                if editingCategoryID == category.id {
                    CategoryFormRow(
                        initialName: category.name,
                        initialIcon: category.icon,
                        initialColor: category.iconColor,
                        placeholder: category.name,
                        onSave: { name, icon, color in
                            viewModel.updateCategory(id: category.id, name: name, icon: icon, colorName: color)
                            editingCategoryID = nil
                        },
                        onCancel: { editingCategoryID = nil }
                    )
                    .tag(category.id)
                } else {
                    let idx = viewModel.sortedCategories.firstIndex(where: { $0.id == category.id }) ?? 0
                    let total = viewModel.sortedCategories.count
                    CategorySidebarRow(
                        category: category,
                        activeCount: viewModel.scripts(for: category).filter { $0.state.isActive }.count,
                        isFirst: idx == 0,
                        isLast: idx == total - 1,
                        onMoveUp: { viewModel.moveCategoryUp(id: category.id) },
                        onMoveDown: { viewModel.moveCategoryDown(id: category.id) }
                    )
                    .tag(category.id)
                    .contextMenu {
                        Button("编辑") {
                            editingCategoryID = category.id
                        }
                        Divider()
                        Button("删除", role: .destructive) {
                            deleteConfirmCategoryID = category.id
                        }
                        .disabled(category.isDevCategory)
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .contextMenu {
            Button("添加分类") {
                editingCategoryID = nil
                isAddingCategory = true
            }
        }
        .confirmationDialog("确认删除该分类？", isPresented: Binding(
            get: { deleteConfirmCategoryID != nil },
            set: { if !$0 { deleteConfirmCategoryID = nil } }
        ), titleVisibility: .visible) {
            Button("删除", role: .destructive) {
                guard let id = deleteConfirmCategoryID else { return }
                if selectedCategoryID == id {
                    selectedCategoryID = viewModel.sortedCategories.first(where: { $0.id != id })?.id
                }
                viewModel.deleteCategory(id: id)
                deleteConfirmCategoryID = nil
            }
        } message: {
            Text("该分类下的脚本将不再显示，但不影响项目文件。")
        }
    }

    // MARK: - Rules Section

    private var rulesSection: some View {
        Group {
            if viewModel.extractRules.isEmpty {
                Color.clear
                    .frame(height: 36)
                    .contentShape(Rectangle())
                    .contextMenu {
                        Button("添加规则") {
                            editingRule = nil
                            showAddRuleDialog = true
                        }
                    }
            } else {
                ScrollView {
                    FlowLayout(horizontalSpacing: 6, verticalSpacing: 6) {
                        ForEach(viewModel.extractRules) { rule in
                            ExtractRuleTag(rule: rule) {
                                editingRule = rule
                                showAddRuleDialog = true
                            } onDelete: {
                                viewModel.deleteExtractRule(id: rule.id)
                            }
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                }
                .frame(maxHeight: 90)
                .contentShape(Rectangle())
                .contextMenu {
                    Button("添加规则") {
                        editingRule = nil
                        showAddRuleDialog = true
                    }
                }
            }
        }
    }
}

// MARK: - Category Form Row (add / edit inline)

struct CategoryFormRow: View {
    let initialName: String
    let initialIcon: String
    let initialColor: String
    let placeholder: String
    let onSave: (String, String, String) -> Void
    let onCancel: () -> Void

    @State private var name: String
    @State private var icon: String
    @State private var colorName: String
    @State private var showIconPicker = false
    @FocusState private var nameFocused: Bool

    init(initialName: String, initialIcon: String, initialColor: String, placeholder: String,
         onSave: @escaping (String, String, String) -> Void, onCancel: @escaping () -> Void) {
        self.initialName = initialName
        self.initialIcon = initialIcon
        self.initialColor = initialColor
        self.placeholder = placeholder
        self.onSave = onSave
        self.onCancel = onCancel
        _name = State(initialValue: initialName)
        _icon = State(initialValue: initialIcon)
        _colorName = State(initialValue: initialColor)
    }

    private var iconColor: Color { Category.swiftUIColor(colorName) }

    var body: some View {
        HStack(spacing: 6) {
            // Icon + color picker
            Button { showIconPicker = true } label: {
                Image(systemName: icon.isEmpty ? "folder.fill" : icon)
                    .font(.callout)
                    .foregroundStyle(iconColor)
                    .frame(width: 22, height: 22)
            }
            .buttonStyle(.plain)
            .popover(isPresented: $showIconPicker, arrowEdge: .bottom) {
                IconPickerView(selectedIcon: $icon, selectedColor: $colorName)
            }
            .onChange(of: showIconPicker) { _, isOpen in
                // Re-focus text field after picker closes so clicking outside still triggers cancel
                if !isOpen { nameFocused = true }
            }

            // Name field
            TextField(placeholder, text: $name)
                .textFieldStyle(.plain)
                .focused($nameFocused)
                .onSubmit { trySave() }
                .onChange(of: nameFocused) { _, isFocused in
                    guard !isFocused else { return }
                    // Brief delay so icon-picker button click doesn't trigger cancel
                    Task { @MainActor in
                        try? await Task.sleep(for: .milliseconds(120))
                        if !showIconPicker { onCancel() }
                    }
                }

            // Save button
            Button { trySave() } label: {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(name.trimmingCharacters(in: .whitespaces).isEmpty
                                     ? AnyShapeStyle(.tertiary) : AnyShapeStyle(iconColor))
            }
            .buttonStyle(.plain)
            .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding(.vertical, 2)
        .onAppear { nameFocused = true }
        .onExitCommand { onCancel() }
    }

    private func trySave() {
        let n = name.trimmingCharacters(in: .whitespaces)
        guard !n.isEmpty else { return }
        onSave(n, icon, colorName)
    }
}

// MARK: - Category Sidebar Row

struct CategorySidebarRow: View {
    let category: Category
    let activeCount: Int
    let isFirst: Bool
    let isLast: Bool
    let onMoveUp: () -> Void
    let onMoveDown: () -> Void

    @State private var isHovered = false

    var body: some View {
        Label {
            HStack(spacing: 4) {
                Text(category.name)
                Spacer()
                if isHovered {
                    HStack(spacing: 2) {
                        Button { onMoveUp() } label: {
                            Image(systemName: "chevron.up").font(.caption2)
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(isFirst ? .quaternary : .secondary)
                        .disabled(isFirst)

                        Button { onMoveDown() } label: {
                            Image(systemName: "chevron.down").font(.caption2)
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(isLast ? .quaternary : .secondary)
                        .disabled(isLast)
                    }
                }
                if activeCount > 0 {
                    Text("\(activeCount)")
                        .font(.caption2).fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(category.accentColor, in: Capsule())
                }
            }
        } icon: {
            Image(systemName: category.icon)
                .foregroundStyle(category.accentColor)
        }
        .onHover { isHovered = $0 }
    }
}

// MARK: - Extract Rule Tag

struct ExtractRuleTag: View {
    let rule: LogExtractRule
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        Text(rule.name)
            .font(.caption)
            .padding(.horizontal, 8).padding(.vertical, 3)
            .background(rule.type.tagColor.opacity(0.12), in: Capsule())
            .overlay(Capsule().stroke(rule.type.tagColor.opacity(0.3), lineWidth: 1))
            .foregroundStyle(rule.type.tagColor)
            .contextMenu {
                Button("编辑", action: onEdit)
                Divider()
                Button("删除", role: .destructive, action: onDelete)
            }
    }
}

// MARK: - Project Switcher Popover

struct ProjectSwitcherPopover: View {
    @Environment(AppViewModel.self) private var viewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("切换项目")
                .font(.caption).fontWeight(.semibold).foregroundStyle(.secondary)
                .padding(.horizontal, 14).padding(.top, 10).padding(.bottom, 6)
            Divider()

            if viewModel.projects.isEmpty {
                Text("暂无项目").font(.callout).foregroundStyle(.secondary)
                    .padding(.horizontal, 14).padding(.vertical, 10)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(viewModel.projects) { project in
                            HStack(spacing: 10) {
                                Image(systemName: project.id == viewModel.currentProject?.id
                                      ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(project.id == viewModel.currentProject?.id
                                                     ? Color.accentColor : .secondary)
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(project.name).font(.callout)
                                    Text(project.packageJSONPath)
                                        .font(.caption2).foregroundStyle(.tertiary)
                                        .lineLimit(1).truncationMode(.middle)
                                }
                                Spacer()
                            }
                            .padding(.horizontal, 14).padding(.vertical, 8)
                            .contentShape(Rectangle())
                            .onTapGesture { viewModel.selectProject(project) }
                            .contextMenu {
                                Button("删除项目", role: .destructive) {
                                    viewModel.removeProject(id: project.id)
                                }
                            }
                        }
                    }
                }
                .frame(maxHeight: 220)
            }

            Divider()
            Button(action: addProject) {
                Label("添加项目", systemImage: "plus").font(.callout)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 14).padding(.vertical, 8)
        }
        .frame(width: 270)
    }

    private func addProject() {
        let panel = NSOpenPanel()
        panel.title = "选择 package.json"
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        if panel.runModal() == .OK, let url = panel.url {
            viewModel.addProject(from: url)
        }
    }
}
