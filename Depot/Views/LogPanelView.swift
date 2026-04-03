import SwiftUI

struct LogPanelView: View {
    let script: Script
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "terminal.fill")
                Text(script.id)
                    .font(.headline)
                    .fontDesign(.monospaced)
                Spacer()
                Text("\(script.logs.count) 行")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.bar)

            Divider()

            // Log content
            if script.logs.isEmpty {
                ContentUnavailableView("暂无日志", systemImage: "doc.text")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 1) {
                            ForEach(Array(script.logs.enumerated()), id: \.offset) { index, line in
                                Text(line)
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundStyle(lineColor(for: line))
                                    .textSelection(.enabled)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 1)
                                    .id(index)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    .onChange(of: script.logs.count) { _, newCount in
                        if newCount > 0 {
                            withAnimation {
                                proxy.scrollTo(newCount - 1, anchor: .bottom)
                            }
                        }
                    }
                    .onAppear {
                        if !script.logs.isEmpty {
                            proxy.scrollTo(script.logs.count - 1, anchor: .bottom)
                        }
                    }
                }
            }

            Divider()

            // Footer with clear button
            HStack {
                Spacer()
                Button("清除日志") {
                    script.logs.removeAll()
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .font(.caption)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
            .background(.bar)
        }
        .frame(minWidth: 640, minHeight: 360)
        .background(.windowBackground)
    }

    private func lineColor(for line: String) -> Color {
        let lower = line.lowercased()
        if lower.contains("error") || lower.contains("err ") || lower.hasPrefix("err") {
            return .red
        } else if lower.contains("warn") {
            return .orange
        } else if lower.contains("success") || lower.contains("done") || lower.contains("built") {
            return .green
        }
        return .primary
    }
}
