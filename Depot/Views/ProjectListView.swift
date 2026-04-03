import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct ProjectListView: View {
    @Environment(AppViewModel.self) private var viewModel

    var body: some View {
        VStack(spacing: 0) {
            headerBar
            Divider()
            if viewModel.projects.isEmpty {
                emptyState
            } else {
                projectList
            }
        }
        .frame(minWidth: 460, minHeight: 360)
    }

    // MARK: - Header

    private var headerBar: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Dev Status Board")
                    .font(.title2).fontWeight(.bold)
                Text("选择一个项目开始")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Button(action: addProject) {
                Label("添加项目", systemImage: "plus")
            }
            .buttonStyle(.bordered)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "shippingbox")
                .font(.system(size: 52))
                .foregroundStyle(.secondary)
            Text("暂无项目").font(.headline)
            Text("点击「添加项目」选择 pnpm/npm 项目的 package.json")
                .font(.subheadline).foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("添加项目", action: addProject)
                .buttonStyle(.borderedProminent)
            Spacer()
        }
        .padding()
    }

    // MARK: - Project List

    private var projectList: some View {
        List {
            ForEach(viewModel.projects) { project in
                ProjectEntryRow(project: project)
                    .contentShape(Rectangle())
                    .onTapGesture { viewModel.selectProject(project) }
                    .contextMenu {
                        Button("删除项目", role: .destructive) {
                            viewModel.removeProject(id: project.id)
                        }
                    }
            }
        }
        .listStyle(.plain)
    }

    // MARK: - Actions

    private func addProject() {
        let panel = NSOpenPanel()
        panel.title = "选择 package.json"
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.nameFieldStringValue = "package.json"
        if panel.runModal() == .OK, let url = panel.url {
            viewModel.addProject(from: url)
        }
    }
}

// MARK: - Row

struct ProjectEntryRow: View {
    let project: ProjectEntry

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "shippingbox.fill")
                .font(.title2)
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 3) {
                Text(project.name)
                    .font(.body).fontWeight(.medium)
                Text(project.packageJSONPath)
                    .font(.caption).foregroundStyle(.secondary)
                    .lineLimit(1).truncationMode(.middle)
            }
            Spacer()
            Image(systemName: "chevron.right").foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }
}
