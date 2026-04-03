import SwiftUI

struct ContentView: View {
    @Environment(AppViewModel.self) private var viewModel
    @State private var selectedCategoryID: String? = nil
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    var body: some View {
        Group {
            if viewModel.currentProject == nil {
                ProjectListView()
                    .frame(minWidth: 460, minHeight: 360)
            } else {
                mainView
            }
        }
        .onChange(of: viewModel.currentProject?.id) {
            selectedCategoryID = viewModel.sortedCategories.first?.id
        }
    }

    private var mainView: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            SidebarView(selectedCategoryID: $selectedCategoryID)
                .navigationSplitViewColumnWidth(min: 180, ideal: 210, max: 280)
        } detail: {
            if let id = selectedCategoryID,
               let category = viewModel.sortedCategories.first(where: { $0.id == id }) {
                ScriptListView(category: category)
            } else {
                ContentUnavailableView("选择分类", systemImage: "sidebar.left",
                    description: Text("从左侧选择一个分类"))
            }
        }
        .frame(minWidth: 700, minHeight: 450)
    }
}

#Preview {
    ContentView()
        .environment(AppViewModel())
}
