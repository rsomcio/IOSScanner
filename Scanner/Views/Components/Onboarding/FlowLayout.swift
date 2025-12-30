//
//  FlowLayout.swift
//  Scanner
//
//  Created on 12/29/25.
//

import SwiftUI

/// Custom layout that arranges views in a flowing horizontal pattern with automatic line breaks
struct FlowLayout: Layout {
    var spacing: CGFloat = 12

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowLayoutResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowLayoutResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.frames[index].minX,
                                     y: bounds.minY + result.frames[index].minY),
                         proposal: ProposedViewSize(result.frames[index].size))
        }
    }

    struct FlowLayoutResult {
        var frames: [CGRect] = []
        var size: CGSize = .zero

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                // Check if we need to wrap to next line
                if currentX + size.width > maxWidth && currentX > 0 {
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }

                // Place subview
                frames.append(CGRect(origin: CGPoint(x: currentX, y: currentY), size: size))

                // Update current position
                currentX += size.width + spacing
                lineHeight = max(lineHeight, size.height)
            }

            // Calculate total size
            let maxX = frames.map { $0.maxX }.max() ?? 0
            let maxY = frames.map { $0.maxY }.max() ?? 0
            self.size = CGSize(width: maxX, height: maxY)
        }
    }
}
