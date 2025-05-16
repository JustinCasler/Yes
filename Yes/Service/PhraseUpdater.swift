//
//  PhraseUpdater.swift
//  Yes
//
//  Created by justin casler on 2/27/25.
//

import Foundation
import FirebaseAuth
import WidgetKit

struct PhraseUpdater {
    static func updateForNewDay(user: inout User) {
        // Reset the done flag for a new day.
        user.done = false

        // Determine available phrase indices.
        let allIndices = Array(0..<Phrases.all.count)
        let usedIndices = user.phrases
        let availableIndices = allIndices.filter { !usedIndices.contains($0) }
        let chosenIndex: Int = availableIndices.randomElement() ?? allIndices.randomElement()!

        // Save the chosen phrase index in shared UserDefaults.
        if let defaults = UserDefaults(suiteName: "group.offline.yes") {
            defaults.set(chosenIndex, forKey: "currentPhraseIndex")
        }
        let newPhrase = Phrases.all[chosenIndex]
        // Generate letter variants and store them.
        let newVariants = PhraseUpdater.generateLetterVariants(for: newPhrase)
        if let defaults = UserDefaults(suiteName: "group.offline.yes") {
            defaults.set(newVariants, forKey: "savedLetterVariants")
        }
        NotificationCenter.default.post(name: .didPerformDailyUpdate, object: nil)

        // Call the completion handler if provided.
        WidgetCenter.shared.reloadTimelines(ofKind: "YesWidget")

    }
    
    static func generateLetterVariants(for phrase: String) -> [Int] {
        var variants: [Int] = []
        for char in phrase.lowercased() {
            if char.isLetter || char.isNumber {
                variants.append(Int.random(in: 1...3))
            }
        }
        return variants
    }
}

