//
//  TallyMarksView.swift
//  Yes
//
//  Created by justin casler on 2/16/25.
//

import SwiftUI
struct FlowLayout: Layout {
    var horizontalSpacing: CGFloat = 8
    var verticalSpacing: CGFloat = 16  // Increased vertical spacing

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        var currentRowWidth: CGFloat = 0
        var totalHeight: CGFloat = 0
        var currentRowHeight: CGFloat = 0
        let maxWidth = proposal.width ?? .infinity

        for subview in subviews {
            let subviewSize = subview.sizeThatFits(.unspecified)
            if currentRowWidth + subviewSize.width > maxWidth {
                totalHeight += currentRowHeight + verticalSpacing
                currentRowWidth = subviewSize.width + horizontalSpacing
                currentRowHeight = subviewSize.height
            } else {
                currentRowWidth += subviewSize.width + horizontalSpacing
                currentRowHeight = max(currentRowHeight, subviewSize.height)
            }
        }
        totalHeight += currentRowHeight
        return CGSize(width: maxWidth, height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var currentRowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX {
                x = bounds.minX
                y += currentRowHeight + verticalSpacing
                currentRowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + horizontalSpacing
            currentRowHeight = max(currentRowHeight, size.height)
        }
    }
}

struct TallyGroup: View {
    /// Number of marks in this group (0...5)
    let markCount: Int
    
    // The total width of 4 lines (each 5 points wide) + spacings = 50
    private let groupWidth: CGFloat = 50
    private let groupHeight: CGFloat = 30
    
    var body: some View {
        ZStack {
            // 4 vertical lines in an HStack
            HStack(spacing: 8) {
                ForEach(0..<min(markCount, 4), id: \.self) { _ in
                    TallyMark()
                        .stroke(Color.black, lineWidth: 2)
                        .frame(width: 5, height: groupHeight)
                }
            }
            // Overlaid slash if markCount == 5
            if markCount == 5 {
                SlashMark()
                    .stroke(Color.black, lineWidth: 2)
                    .frame(width: groupWidth, height: groupHeight)
            }
        }
        .frame(width: groupWidth, height: groupHeight)
    }
}

struct TallyMarksView: View {
    let count: Int  // The user's streak

    // Compute groups of tally marks (each group represents up to 5 marks)
    var groups: [Int] {
        let fullGroups = count / 5
        let remainder = count % 5
        var result = Array(repeating: 5, count: fullGroups)
        if remainder > 0 {
            result.append(remainder)
        }
        return result
    }
    
    // A simple function to provide a small offset for each tally group
    private func offset(for index: Int) -> CGSize {
        // A pattern of small offsets that repeats.
        let offsets: [CGSize] = [
            CGSize(width: -2, height: 2),
            CGSize(width: 1, height: -1),
            CGSize(width: 2, height: 1),
            CGSize(width: -1, height: -2)
        ]
        return offsets[index % offsets.count]
    }

    var body: some View {
        FlowLayout(horizontalSpacing: 8, verticalSpacing: 16) {
            Text("Days in a row:")
                .font(.custom("Bradley Hand", size: 30))
                .foregroundColor(.black)
            ForEach(groups.indices, id: \.self) { index in
                TallyGroup(markCount: groups[index])
                    .offset(offset(for: index))
            }
        }
        .padding()
    }
}



#Preview {
    // TallyGroup(markCount: 11)
    TallyMarksView(count: 56)
}
