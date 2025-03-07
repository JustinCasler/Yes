//
//  PhraseManager.swift
//  Yes
//
//  Created by justin casler on 2/27/25.
//

import Foundation 
import WidgetKit

class PhraseManager { 
    static let shared = PhraseManager()

private init() { }

func updateDailyPhrase(completion: (() -> Void)? = nil) {
    let calendar = Calendar.current
    // Use UserDefaults from your shared App Group
    guard let defaults = UserDefaults(suiteName: "group.offline.yes") else {
        completion?()
        return
    }
    
    // Check if a new day has begun. You might need to store last update date in defaults.
    let lastUpdate = defaults.object(forKey: "lastUpdate") as? Date ?? Date.distantPast
    if !calendar.isDateInToday(lastUpdate) {
        // New day: select a new phrase.
        let allIndices = Array(0..<Phrases.all.count)
        // For widget logic, you might not have access to user.phrases (used phrases),
        // so here we simply choose a random index.
        let chosenIndex = allIndices.randomElement() ?? 0
        defaults.set(chosenIndex, forKey: "currentPhraseIndex")
        
        let newPhrase = Phrases.all[chosenIndex]
        // Generate new letter variants.
        let newVariants = generateLetterVariants(for: newPhrase)
        defaults.set(newVariants, forKey: "savedLetterVariants")
        
        // Update the last update date.
        defaults.set(Date(), forKey: "lastUpdate")
        
        // Trigger a widget refresh.
        WidgetCenter.shared.reloadTimelines(ofKind: "YesWidget")
    }
    completion?()
}

private func generateLetterVariants(for phrase: String) -> [Int] {
    var variants: [Int] = []
    for char in phrase.lowercased() {
        if char.isLetter || char.isNumber {
            variants.append(Int.random(in: 1...3))
        }
    }
    return variants
}
}

