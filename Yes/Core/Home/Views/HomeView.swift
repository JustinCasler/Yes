//
//  HomeView.swift
//  Yes
//
//  Created by justin casler on 2/15/25.
//

import SwiftUI

struct HomeView: View {
    @ObservedObject var viewModel: HomeViewModel
    @ObservedObject var authViewModel = AuthViewModel()
    @AppStorage("hasSeenWelcomePopup") private var hasSeenWelcomePopup = false
    @State private var showWelcome = false


    let user: User
    let letterSpacing: CGFloat = 4
    let wordSpacing: CGFloat = 16
    let imageSize: CGFloat = 35
    
    var words: [String] {
        viewModel.currentPhrase.components(separatedBy: " ")
    }
    
    init(user: User) {
        self.user = user
        self.viewModel = HomeViewModel(user: user)
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
                                Text("Re-Roll (\(viewModel.user.rerolls))")
                                Image(systemName: "arrow.clockwise.circle")
                            }
                        }
                        .disabled(viewModel.user.rerolls <= 0)
                        
                        Button(action: {
                            let generator = UIImpactFeedbackGenerator(style: .medium)
                            generator.impactOccurred()
                            viewModel.toggleDoneStatus()
                        }) {
                            HStack {
                                Text("Done")
                                Image(systemName: viewModel.user.done ? "checkmark.square" : "square")
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
            viewModel.checkRerollEligibility() // Add a reroll if a week has passed.
            viewModel.updatePhraseOnNewDay()   // Update phrase if last sign-in was yesterday.
        }
    }
}

#Preview {
    HomeView(user: User(
        id: nil,
        fullName: "",
        streak: 2,
        phrases: [],
        rerolls: 2,
        rerollDate: Date(),
        lastSignIn: Date(),
        done: false,
        updatedPhraseDate: Date()
    ))
}
