import SwiftUI

/// A layout that wraps its children onto new lines like CSS flexbox-wrap.
struct FlowLayout: Layout {
    var horizontalSpacing: CGFloat = 8
    var verticalSpacing: CGFloat = 8

    private struct Row {
        var indices: [Int]
        var y: CGFloat
        var height: CGFloat
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = makeRows(subviews: subviews, width: proposal.width ?? .infinity)
        let height = rows.last.map { $0.y + $0.height } ?? 0
        return CGSize(width: proposal.width ?? 0, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = makeRows(subviews: subviews, width: bounds.width)
        for row in rows {
            var x = bounds.minX
            for i in row.indices {
                let size = subviews[i].sizeThatFits(.unspecified)
                subviews[i].place(at: CGPoint(x: x, y: bounds.minY + row.y), proposal: .unspecified)
                x += size.width + horizontalSpacing
            }
        }
    }

    private func makeRows(subviews: Subviews, width: CGFloat) -> [Row] {
        var rows: [Row] = []
        var currentIndices: [Int] = []
        var currentWidth: CGFloat = 0
        var currentHeight: CGFloat = 0
        var y: CGFloat = 0

        for (i, subview) in subviews.enumerated() {
            let size = subview.sizeThatFits(.unspecified)
            let needed = currentIndices.isEmpty
                ? size.width
                : currentWidth + horizontalSpacing + size.width

            if !currentIndices.isEmpty && needed > width {
                rows.append(Row(indices: currentIndices, y: y, height: currentHeight))
                y += currentHeight + verticalSpacing
                currentIndices = [i]; currentWidth = size.width; currentHeight = size.height
            } else {
                currentIndices.append(i)
                currentWidth = needed
                currentHeight = max(currentHeight, size.height)
            }
        }
        if !currentIndices.isEmpty {
            rows.append(Row(indices: currentIndices, y: y, height: currentHeight))
        }
        return rows
    }
}
