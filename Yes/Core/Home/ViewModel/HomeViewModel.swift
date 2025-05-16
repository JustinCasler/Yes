//
//  HomeViewModel.swift
//  Yes
//
//  Created by justin casler on 2/20/25.
//

import Foundation
import Combine
class HomeViewModel: ObservableObject {
    @Published var currentUser: User?
    private var cancellables = Set<AnyCancellable>()
    @Published var currentPhrase: String = "default"
    @Published var letterVariants: [Int] = []
    
    init() {
        setup()
    }
    private func setup(){
        UserService.shared.$currentUser.sink { [weak self] user in
            self?.currentUser = user
        }.store(in: &cancellables)
    }
    func generateLetterVariants(for phrase: String) -> [Int] {
        var variants: [Int] = []
        for char in phrase.lowercased() {
            if char.isLetter || char.isNumber {
                variants.append(Int.random(in: 1...3))
            }
        }
        return variants
    }
    
    // If so, increment rerolls and update rerollDate in Firestore.
    func checkRerollEligibility() {
        let calendar = Calendar.current
        if let nextEligibleDate = calendar.date(byAdding: .day, value: 7, to: currentUser!.rerollDate) {
            if Date() >= nextEligibleDate {
                currentUser!.rerolls += 1
                currentUser!.rerollDate = Date()
                
                UserService.shared.updateUser(currentUser!) { error in
                    if let error = error {
                        print("Error updating user in checkRerollEligibility: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    // reset the done property, and update the changes in Firestore.
    func performReroll() {
        if currentUser!.rerolls > 0 {
            currentUser!.rerolls -= 1
            
            currentUser!.done = false
            
            UserService.shared.updateUser(currentUser!) { error in
                if let error = error {
                    print("Error updating user in performReroll: \(error.localizedDescription)")
                }
            }
            
            PhraseUpdater.updateForNewDay(user: &currentUser!)
            
            setPhrasesAndVariants(user: currentUser!)
        }
    }
    
    // update lastSignIn and done flag, and push these changes to Firestore.
    func updatePhraseOnNewDay() {
        let calendar = Calendar.current
        var newUser = currentUser!

        if !calendar.isDateInToday(newUser.lastSignIn) {
            if calendar.isDateInYesterday(newUser.lastSignIn) {
                
            } else {
                newUser.streak = 1
            }
            UserService.shared.updateUser(newUser) { error in
                if let e = error {
                    print("Error updating streak/lastSignIn:", e.localizedDescription)
                }
            }
        }
        guard !calendar.isDateInToday(newUser.updatedPhraseDate) else {
            // already updated → just drive the UI
            setPhrasesAndVariants(user: newUser)
            return
        }
        PhraseUpdater.updateForNewDay(user: &newUser)

        newUser.updatedPhraseDate = Date()
        UserService.shared.updateUser(newUser) { error in
            if let e = error {
                print("Error persisting updatedPhraseDate:", e.localizedDescription)
            }
        }

        // 5) push it into your @Published and refresh the UI
        DispatchQueue.main.async {
            self.currentUser = newUser
            self.setPhrasesAndVariants(user: newUser)
        }
    }

    func setPhrasesAndVariants(user: User) {
        // Get the shared UserDefaults instance.
        guard let defaults = UserDefaults(suiteName: "group.offline.yes") else { return }
        
        var phrase: String?
        // Try to retrieve the stored phrase index.
        if let storedPhraseIndex = defaults.value(forKey: "currentPhraseIndex") as? Int,
           storedPhraseIndex < Phrases.all.count {
            phrase = Phrases.all[storedPhraseIndex]
        } else {
            let allIndices = Array(0..<Phrases.all.count)
            let usedIndices = user.phrases
            let availableIndices = allIndices.filter { !usedIndices.contains($0) }
            let chosenIndex: Int = availableIndices.randomElement() ?? allIndices.randomElement()!
            defaults.set(chosenIndex, forKey: "currentPhraseIndex")
            phrase = Phrases.all[chosenIndex]
        }
        
        // If we have a valid phrase, update the UI and check for letter variants.
        if let validPhrase = phrase {
            DispatchQueue.main.async {
                self.currentPhrase = validPhrase
            }
            
            // Check for saved letter variants.
            if let storedVariants = defaults.value(forKey: "savedLetterVariants") as? [Int] {
                DispatchQueue.main.async {
                    self.letterVariants = storedVariants
                }
            } else {
                // No variants stored – generate new ones.
                let newVariants = generateLetterVariants(for: validPhrase)
                defaults.set(newVariants, forKey: "savedLetterVariants")
                DispatchQueue.main.async {
                    self.letterVariants = newVariants
                }
            }
        }
    }

    
    // Toggle the done status. If toggled on, add the current phrase's index to the user's phrases array;
    // if toggled off, remove it, then update Firestore.
    // streak update if done is clicked
    // lastsignin === last streak day
    func toggleDoneStatus() {
        let calendar = Calendar.current

        currentUser!.done.toggle()

        if currentUser!.done {
            currentUser!.streak += 1
            currentUser!.lastSignIn = Date()
        } else {
            currentUser!.streak = max(1, currentUser!.streak - 1)
            if let yesterday = calendar.date(byAdding: .day, value: -1, to: Date()) {
                currentUser!.lastSignIn = yesterday
            }
        }
        let chosenIndex: Int
        if let defaults = UserDefaults(suiteName: "group.offline.yes") {
            chosenIndex = defaults.integer(forKey: "currentPhraseIndex")
        } else {
            chosenIndex = 0
        }
        
        if currentUser!.done {
            if currentUser!.phrases.last != chosenIndex {
                currentUser!.phrases.append(chosenIndex)
            }
        } else {
            if let last = currentUser!.phrases.last, last == chosenIndex {
                currentUser!.phrases.removeLast()
            }
        }
        
        UserService.shared.updateUser(currentUser!) { error in
            if let error = error {
                print("Error updating user in toggleDoneStatus: \(error.localizedDescription)")
            }
        }
    }
}
