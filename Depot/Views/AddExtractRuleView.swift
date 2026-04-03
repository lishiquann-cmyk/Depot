import SwiftUI

struct AddExtractRuleView: View {
    @Binding var isPresented: Bool
    var ruleToEdit: LogExtractRule? = nil
    var onSave: (LogExtractRule) -> Void

    @State private var name = ""
    @State private var type: ExtractType = .url
    @State private var prefix = ""
    @FocusState private var nameFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text(ruleToEdit == nil ? "添加提取规则" : "编辑提取规则")
                    .font(.headline)
                Spacer()
                Button { isPresented = false } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(16)

            Divider()

            VStack(alignment: .leading, spacing: 14) {
                // Name
                VStack(alignment: .leading, spacing: 4) {
                    Text("名称").font(.caption).foregroundStyle(.secondary)
                    TextField("如：Vue 本地地址", text: $name)
                        .textFieldStyle(.roundedBorder)
                        .focused($nameFocused)
                }

                // Type picker
                VStack(alignment: .leading, spacing: 4) {
                    Text("类型").font(.caption).foregroundStyle(.secondary)
                    Picker("", selection: $type) {
                        ForEach(ExtractType.allCases, id: \.self) { t in
                            Label(t.label,
                                  systemImage: t == .url ? "link" : "folder").tag(t)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                }

                // Prefix
                VStack(alignment: .leading, spacing: 4) {
                    Text("日志前缀").font(.caption).foregroundStyle(.secondary)
                    TextField("如：➜  Local:", text: $prefix)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.body, design: .monospaced))
                    Text("匹配以此前缀开头的日志行，将后面的内容提取为\(type.label)")
                        .font(.caption2).foregroundStyle(.tertiary)
                }
            }
            .padding(16)

            Divider()

            HStack {
                Button("取消") { isPresented = false }
                    .buttonStyle(.plain).foregroundStyle(.secondary)
                Spacer()
                Button("保存") { save() }
                    .buttonStyle(.borderedProminent)
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty ||
                              prefix.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(16)
        }
        .frame(width: 360)
        .onAppear {
            if let rule = ruleToEdit {
                name = rule.name; type = rule.type; prefix = rule.prefix
            }
            nameFocused = true
        }
    }

    private func save() {
        let rule = LogExtractRule(
            id: ruleToEdit?.id ?? UUID(),
            name: name.trimmingCharacters(in: .whitespaces),
            type: type,
            prefix: prefix,
            order: ruleToEdit?.order ?? 0
        )
        onSave(rule)
        isPresented = false
    }
}
