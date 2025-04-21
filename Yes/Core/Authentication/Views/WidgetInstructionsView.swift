//
//  WidgetInstructionsView.swift
//  Yes
//
//  Created by justin casler on 4/6/25.
//

import SwiftUI

struct WidgetInstructionsView: View {
    var onContinue: () -> Void

    var body: some View {
        ZStack {
            Image("Paper")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Text("To add a widget on your phone's home screen, touch and hold an empty area, then tap on Edit.")
                    .foregroundColor(.black)
                    .font(.custom("Courier", size: 20))
                    .multilineTextAlignment(.center)
                    .padding()
                    .frame(maxWidth: 350)
                    .fixedSize(horizontal: false, vertical: true)
                Image("Widget_Instructions")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 400)
                    .clipShape(RoundedCorner(radius: 30, corners: [.topLeft, .topRight, .bottomLeft, .bottomRight]))

                Spacer().frame(height: 20)

                VStack(spacing: 12) {
                    Button("continue") {
                        onContinue()
                    }
                    .frame(maxWidth: 300, minHeight: 50)
                    .background(Color.black)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
            }
            .padding()
        }
    }
}
#Preview {
    WidgetInstructionsView(onContinue: {})
}
