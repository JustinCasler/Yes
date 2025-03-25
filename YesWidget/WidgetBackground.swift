//
//  WidgetBackground.swift
//  YesWidgetExtension
//
//  Created by justin casler on 3/23/25.
//

import SwiftUI

extension View {
    @ViewBuilder
    func widgetBackground<T: View>(@ViewBuilder content: () -> T) -> some View {
        if #available(iOS 17.0, *) {
            containerBackground(for: .widget, content: content)
        } else {
            background(content())
        }
    }
}
