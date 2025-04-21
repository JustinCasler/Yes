//
//  WelcomePopupView.swift
//  Yes
//
//  Created by justin casler on 4/6/25.
//

import SwiftUI

struct WelcomePopupView: View {
    var onDismiss: () -> Void

    @GestureState private var dragOffset: CGSize = .zero
    @State private var offsetY: CGFloat = 0

    var body: some View {
        GeometryReader { geometry in
            let bottomInset = geometry.safeAreaInsets.bottom
            VStack {
                Spacer()

                ZStack(alignment: .top) {
                    Color.white
                        .frame(height: geometry.size.height + bottomInset)
                        .cornerRadius(30, corners: [.topLeft, .topRight])
                        .shadow(radius: 15)

                    VStack(spacing: 16) {
                        Capsule()
                            .fill(Color.secondary)
                            .frame(width: 40, height: 5)
                            .padding(.top, 2)

                        Text("Hey!")
                            .font(.custom("Courier", size: 16))
                            .bold()

                        Text("""
                            I created this app to remind us to say yes to life daily. I found it’s getting easier and easier to stay inside, be on social media, and interact with people less. It's easy to let time pass and lose our lives to the phone you're reading this on.

                            I want this app to serve as a daily reminder to take risks, do things you love, and live life to its fullest.
                            """)
                            .font(.custom("Courier", size: 16))
                            .multilineTextAlignment(.center)
                            .frame(width: geometry.size.width * 0.3)
                        Text("I hope you Say Yes")
                            .font(.custom("Courier", size: 16))
                        Text("Best, Justin")
                            .font(.custom("Courier", size: 16))
                    }
                    .padding(.top, 4)
                    .padding(.horizontal)
                    .foregroundColor(.black)
                }
                .frame(height: geometry.size.height)
                .frame(maxWidth: .infinity)
                .offset(y: offsetY + dragOffset.height)
                .gesture(
                    DragGesture()
                        .updating($dragOffset) { value, state, _ in
                            if value.translation.height > 0 {
                                state = value.translation
                            }
                        }
                        .onEnded { value in
                            if value.translation.height > 100 {
                                withAnimation {
                                    onDismiss()
                                }
                            } else {
                                withAnimation {
                                    offsetY = 0
                                }
                            }
                        }
                )
                .transition(.move(edge: .bottom))
            }
            .ignoresSafeArea()
        }
        .animation(.easeOut, value: dragOffset)
    }
}
