import SwiftUI

struct BuildDeployScriptRow: View {
    let script: Script
    let accentColor: Color
    @Environment(AppViewModel.self) private var viewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 12) {
                actionButton

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

                HStack(spacing: 8) {
                    outputInfoView
                    logsButton
                }
            }

            if script.state == .loading {
                ProgressView()
                    .progressViewStyle(.linear)
                    .tint(accentColor)
                    .padding(.leading, 60)
            }
        }
        .sheet(isPresented: Binding(
            get: { script.showLogs },
            set: { script.showLogs = $0 }
        )) {
            LogPanelView(script: script)
        }
    }

    // MARK: - Action button

    @ViewBuilder
    private var actionButton: some View {
        switch script.state {
        case .loading:
            HStack(spacing: 4) {
                ProgressView().scaleEffect(0.75).frame(width: 16, height: 16)
                Button(action: { viewModel.stopScript(script) }) {
                    Image(systemName: "stop.circle").font(.title3)
                }
                .buttonStyle(.plain).foregroundStyle(.secondary).help("终止")
            }
            .frame(width: 48, alignment: .center)

        default:
            Button(action: { viewModel.startScript(script) }) {
                Image(systemName: "play.circle.fill").font(.title3).foregroundStyle(accentColor)
            }
            .buttonStyle(.plain).help("运行")
            .frame(width: 48, alignment: .center)
        }
    }

    // MARK: - Output info

    @ViewBuilder
    private var outputInfoView: some View {
        switch script.state {
        case .completed:
            completedOutputView
        case .failed(let msg):
            HStack(spacing: 4) {
                Image(systemName: "xmark.circle.fill").foregroundStyle(.red)
                Text(msg).font(.caption).foregroundStyle(.red).lineLimit(1)
            }
        default:
            EmptyView()
        }
    }

    @ViewBuilder
    private var completedOutputView: some View {
        HStack(spacing: 6) {
            Image(systemName: "checkmark.circle.fill").foregroundStyle(.green).font(.caption)
            if let url = script.extractedURL {
                Button(action: { viewModel.openURL(url) }) {
                    Text(url.absoluteString)
                        .font(.caption).lineLimit(1).truncationMode(.middle)
                        .foregroundStyle(.blue)
                }
                .buttonStyle(.plain).help("在浏览器中打开")
            } else if let path = script.extractedPath {
                Button(action: { viewModel.openFolder(path) }) {
                    HStack(spacing: 3) {
                        Image(systemName: "folder.fill").font(.caption)
                        Text(path).font(.caption).lineLimit(1).truncationMode(.middle)
                    }
                    .foregroundStyle(accentColor)
                }
                .buttonStyle(.plain).help("在 Finder 中打开")
            } else {
                Text("已完成").font(.caption).foregroundStyle(.green)
            }
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
