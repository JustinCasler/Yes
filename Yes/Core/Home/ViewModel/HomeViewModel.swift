//
//  HomeViewModel.swift
//  Yes
//
//  Created by justin casler on 2/20/25.
//

import Foundation
import Firebase
import FirebaseAuth

class HomeViewModel: ObservableObject {
    @Published var user: User
    let userService = UserService()
    var uid: String?
    
    @Published var currentPhrase: String = "default"
    @Published var letterVariants: [Int] = []
    
    init(user: User) {
        self.user = user
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
    
    // 1. Check if a week has passed since rerollDate.
    // If so, increment rerolls and update rerollDate in Firestore.
    func checkRerollEligibility() {
        let calendar = Calendar.current
        if let nextEligibleDate = calendar.date(byAdding: .day, value: 7, to: user.rerollDate) {
            if Date() >= nextEligibleDate {
                user.rerolls += 1
                user.rerollDate = Date()
                
                userService.updateUser(user) { error in
                    if let error = error {
                        print("Error updating user in checkRerollEligibility: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    // 2. When the reroll button is clicked, decrement rerolls (if available), pick a new phrase,
    // reset the done property, and update the changes in Firestore.
    func performReroll() {
        if user.rerolls > 0 {
            user.rerolls -= 1
            
            user.done = false
            
            userService.updateUser(user) { error in
                if let error = error {
                    print("Error updating user in performReroll: \(error.localizedDescription)")
                }
            }
            
            PhraseUpdater.updateForNewDay(user: &user) {
            }
            setPhrasesAndVariants(user: user)
        }
    }
    
    // 3. When it's a new day (i.e. the user's lastSignIn is not today), update the phrase,
    // update lastSignIn and done flag, and push these changes to Firestore.
    func updatePhraseOnNewDay() {
        let calendar = Calendar.current
        var newUser = user

        // 1) streak & lastSignIn as before
        if !calendar.isDateInToday(newUser.lastSignIn) {
            if calendar.isDateInYesterday(newUser.lastSignIn) {
                newUser.streak += 1
            } else {
                newUser.streak = 1
            }
            newUser.lastSignIn = Date()
            userService.updateUser(newUser) { error in
                if let e = error {
                    print("Error updating streak/lastSignIn:", e.localizedDescription)
                }
            }
        }
        print("1")
        // 2) have we already done today’s phrase?
        guard !calendar.isDateInToday(newUser.updatedPhraseDate) else {
            // already updated → just drive the UI
            setPhrasesAndVariants(user: newUser)
            print("2")
            return
        }
        print("3")
        // 3) do the in-out phrase update (synchronous)
        PhraseUpdater.updateForNewDay(user: &newUser) {
        }

        // 4) now that `inout` is finished, it’s safe to stamp
        newUser.updatedPhraseDate = Date()
        userService.updateUser(newUser) { error in
            if let e = error {
                print("Error persisting updatedPhraseDate:", e.localizedDescription)
            }
        }

        // 5) push it into your @Published and refresh the UI
        DispatchQueue.main.async {
            self.user = newUser
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
            // No stored phrase index found – pick a new phrase.
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
    func toggleDoneStatus() {
        user.done.toggle()
        
        let chosenIndex: Int
        if let defaults = UserDefaults(suiteName: "group.offline.yes") {
            chosenIndex = defaults.integer(forKey: "currentPhraseIndex")
        } else {
            chosenIndex = 0
        }
        
        if user.done {
            if user.phrases.last != chosenIndex {
                user.phrases.append(chosenIndex)
            }
        } else {
            if let last = user.phrases.last, last == chosenIndex {
                user.phrases.removeLast()
            }
        }
        
        userService.updateUser(user) { error in
            if let error = error {
                print("Error updating user in toggleDoneStatus: \(error.localizedDescription)")
            }
        }
    }
}
