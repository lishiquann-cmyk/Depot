import SwiftUI

struct DevScriptRow: View {
    let script: Script
    @Environment(AppViewModel.self) private var viewModel

    private var isOn: Bool { script.state.isActive }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 12) {
                // Toggle switch
                Toggle("", isOn: Binding(
                    get: { isOn },
                    set: { newValue in
                        newValue ? viewModel.startScript(script) : viewModel.stopScript(script)
                    }
                ))
                .labelsHidden()
                .toggleStyle(.switch)
                .tint(.green)

                // Script name + command
                VStack(alignment: .leading, spacing: 2) {
                    Text(script.id)
                        .font(.system(.body, design: .monospaced))
                        .fontWeight(.medium)
                    Text(script.command)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                // Right: status info + logs button
                HStack(spacing: 8) {
                    statusView
                    logsButton
                }
            }

            // Inline loading bar
            if script.state == .loading {
                ProgressView()
                    .progressViewStyle(.linear)
                    .tint(.green)
                    .padding(.leading, 44)
            }
        }
        .sheet(isPresented: Binding(
            get: { script.showLogs },
            set: { script.showLogs = $0 }
        )) {
            LogPanelView(script: script)
        }
    }

    // MARK: - Status

    @ViewBuilder
    private var statusView: some View {
        switch script.state {
        case .loading:
            HStack(spacing: 6) {
                ProgressView().scaleEffect(0.7).frame(width: 14, height: 14)
                Text("启动中").font(.caption).foregroundStyle(.secondary)
            }
        case .running:
            if let url = script.extractedURL {
                Button(action: { viewModel.openURL(url) }) {
                    HStack(spacing: 4) {
                        Image(systemName: "link").font(.caption)
                        Text(url.absoluteString)
                            .font(.caption)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                    .foregroundStyle(.green)
                }
                .buttonStyle(.plain)
                .help("在浏览器中打开")
            } else {
                Label("运行中", systemImage: "circle.fill")
                    .font(.caption).foregroundStyle(.green)
            }
        case .failed(let msg):
            Text(msg).font(.caption).foregroundStyle(.red).lineLimit(1)
        default:
            EmptyView()
        }
    }

    // MARK: - Logs button

    private var logsButton: some View {
        Button(action: { script.showLogs = true }) {
            Image(systemName: script.logs.isEmpty ? "doc.text" : "doc.text.magnifyingglass")
                .font(.callout)
        }
        .buttonStyle(.plain)
        .foregroundStyle(script.logs.isEmpty ? .tertiary : .secondary)
        .help(script.logs.isEmpty ? "暂无日志" : "查看日志")
        .disabled(script.logs.isEmpty)
    }
}
