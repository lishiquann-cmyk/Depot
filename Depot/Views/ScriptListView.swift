import SwiftUI

struct ScriptListView: View {
    let category: Category
    @Environment(AppViewModel.self) private var viewModel

    private var scripts: [Script] { viewModel.scripts(for: category) }

    var body: some View {
        Group {
            if scripts.isEmpty {
                ContentUnavailableView(
                    "无 \(category.name) 脚本",
                    systemImage: category.icon,
                    description: Text("当前 package.json 中没有 \(category.keyPrefix) 前缀的脚本")
                )
            } else {
                List {
                    ForEach(scripts) { script in
                        Group {
                            if script.isDevStyle {
                                DevScriptRow(script: script)
                            } else {
                                BuildDeployScriptRow(script: script, accentColor: category.accentColor)
                            }
                        }
                        .listRowInsets(EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12))
                    }
                }
                .listStyle(.inset)
            }
        }
        .navigationTitle(category.name)
        .navigationSubtitle("\(scripts.count) 个脚本")
    }
}
