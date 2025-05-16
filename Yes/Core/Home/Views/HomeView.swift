//
//  HomeView.swift
//  Yes
//
//  Created by justin casler on 2/15/25.
//

import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @AppStorage("hasSeenWelcomePopup") private var hasSeenWelcomePopup = false
    @State private var showWelcome = false

    private var currentUser: User? {
        return viewModel.currentUser
    }
    let letterSpacing: CGFloat = 4
    let wordSpacing: CGFloat = 16
    let imageSize: CGFloat = 35
    
    var words: [String] {
        viewModel.currentPhrase.components(separatedBy: " ")
    }
    
    var body: some View {
        ZStack {
            // Background Image
            Image("Paper")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
            
            // Main content: phrase display and fixed buttons
            VStack {
                // Upper area for the phrase
                VStack(alignment: .center, spacing: wordSpacing) {
                    ForEach(Array(words.enumerated()), id: \.offset) { wordIndex, word in
                        // Compute a custom image size based on word length.
                        let currentImageSize = word.count > 10 ? CGFloat(28) : imageSize
                        let offset = words[..<wordIndex].reduce(0) { $0 + $1.count }
                        
                        HStack(spacing: letterSpacing) {
                            ForEach(Array(word.enumerated()), id: \.offset) { letterIndex, letter in
                                if letter.isLetter || letter.isNumber {
                                    let globalIndex = offset + letterIndex
                                    let variant = (globalIndex < viewModel.letterVariants.count) ? viewModel.letterVariants[globalIndex] : 1
                                    let imageName = "\(String(letter).lowercased())_\(variant)"
                                    
                                    Image(imageName)
                                        .resizable()
                                        .frame(width: currentImageSize, height: currentImageSize)

                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
                .padding()
                .frame(maxHeight: .infinity, alignment: .center)
            
                // Fixed lower area for buttons
                HStack {
                    VStack(alignment: .leading, spacing: 16) {
                        Button(action: {
                            let generator = UIImpactFeedbackGenerator(style: .medium)
                            generator.impactOccurred()
                            viewModel.performReroll()
                        }) {
                            HStack {
                                Text("Re-Roll (\(currentUser!.rerolls))")
                                Image(systemName: "arrow.clockwise.circle")
                            }
                        }
                        .disabled(currentUser!.rerolls <= 0)
                        
                        Button(action: {
                            let generator = UIImpactFeedbackGenerator(style: .medium)
                            generator.impactOccurred()
                            viewModel.toggleDoneStatus()
                        }) {
                            HStack {
                                Text("Done")
                                Image(systemName: currentUser!.done ? "checkmark.square" : "square")
                            }
                        }
                    }
                    .foregroundColor(.black)
                    .font(.custom("Bradley Hand", size: 40))
                }
                .padding()
                .padding(.bottom, 40)
            }
            if showWelcome {
                WelcomePopupView {
                    withAnimation {
                        hasSeenWelcomePopup = true
                        showWelcome = false
                    }
                }
            }
        }
        .onAppear {
            if !hasSeenWelcomePopup {
                withAnimation {
                    showWelcome = true
                }
            }
            viewModel.checkRerollEligibility()
            viewModel.updatePhraseOnNewDay()
            AuthViewModel.shared.updateUserFCMTokenAndTimezone()
        }
        .onReceive(NotificationCenter.default.publisher(for: .didPerformDailyUpdate)) { _ in
            viewModel.setPhrasesAndVariants(user: currentUser!)
        }
    }
}
/*
#Preview {
    HomeView()
}
*/
