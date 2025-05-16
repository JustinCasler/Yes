//
//  TallyShapes.swift
//  Yes
//
//  Created by justin casler on 2/16/25.
//

import SwiftUI

/// A single vertical tally line
struct TallyMark: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        return path
    }
}

/// A diagonal slash (for the 5th tally in a group)
struct SlashMark: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        path.move(to: CGPoint(x: rect.minX, y: rect.midY - 8))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY + 8))
        
        return path
    }
}
