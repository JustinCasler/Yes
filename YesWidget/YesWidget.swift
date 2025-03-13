//
//  YesWidget.swift
//  YesWidget
//
//  Created by justin casler on 2/25/25.
//

import WidgetKit
import SwiftUI

struct SimpleEntry: TimelineEntry {
    let date: Date
    let phrase: String
}

struct Provider: TimelineProvider {
    
    // Returns a placeholder entry for widget previews.
    func placeholder(in context: Context) -> SimpleEntry {
        return SimpleEntry(date: Date(), phrase: Phrases.all.first ?? "Hello")
    }
    
    // Provides a snapshot entry for the widget gallery.
    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), phrase: getCurrentPhrase())
        completion(entry)
    }
    
    // Creates a timeline that updates once at the next midnight.
    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> ()) {
        let now = Date()
        let entry = SimpleEntry(date: now, phrase: getCurrentPhrase())
        
        // Calculate next midnight in the user's local time zone.
        var calendar = Calendar.current
        calendar.timeZone = TimeZone.current
        guard let nextMidnight = calendar.nextDate(
            after: now,
            matching: DateComponents(hour: 0, minute: 0, second: 0),
            matchingPolicy: .strict
        ) else {
            let timeline = Timeline(entries: [entry], policy: .atEnd)
            completion(timeline)
            return
        }
        
        // Create a timeline that updates after next midnight.
        let timeline = Timeline(entries: [entry], policy: .after(nextMidnight))
        completion(timeline)
    }
    
    // Helper to fetch the current phrase based on an index from UserDefaults.
    func getCurrentPhrase() -> String {
        let defaults = UserDefaults(suiteName: "group.offline.yes")
        let index = defaults?.integer(forKey: "currentPhraseIndex") ?? 0
        let safeIndex = index % Phrases.all.count
        return Phrases.all[safeIndex]
    }
}

struct YesWidgetEntryView: View {
    var entry: Provider.Entry
    
    let letterSpacing: CGFloat = 4
    let wordSpacing: CGFloat = 16
    let imageSize: CGFloat = 24
    
    // Retrieve letter variants from the shared user defaults
    var letterVariants: [Int] {
        let defaults = UserDefaults(suiteName: "group.offline.yes") // Update to your App Group identifier
        return defaults?.array(forKey: "savedLetterVariants") as? [Int] ?? []
    }
    
    var body: some View {
        ZStack {
            /* Background Image
            Image("Paper")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .edgesIgnoringSafeArea(.all) // Ensures the image covers the entire widget
            */
            // Foreground Content
            VStack(alignment: .center, spacing: wordSpacing) {
                ForEach(Array(entry.phrase.components(separatedBy: " ").enumerated()), id: \.offset) { wordIndex, word in
                    // Compute an offset based on previous words (if needed)
                    let offset = entry.phrase.components(separatedBy: " ").prefix(wordIndex).reduce(0) { $0 + $1.count }
                    HStack(spacing: letterSpacing) {
                        ForEach(Array(word.enumerated()), id: \.offset) { letterIndex, letter in
                            if letter.isLetter || letter.isNumber {
                                let globalIndex = offset + letterIndex
                                let variant = (globalIndex < letterVariants.count) ? letterVariants[globalIndex] : 1
                                let imageName = "\(String(letter).lowercased())_\(variant)"
                                Image(imageName)
                                    .resizable()
                                    .frame(width: imageSize, height: imageSize)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .padding()
        }
    }
}

struct YesWidget: Widget {
    let kind: String = "YesWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(iOS 17.0, *) {
                YesWidgetEntryView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                YesWidgetEntryView(entry: entry)
                    .padding()
                    .background(Color(.systemBackground))
            }
        }
        .configurationDisplayName("Daily Phrase")
        .description("Displays a daily phrase from your list.")
        .supportedFamilies([.systemMedium])
    }
}

#Preview(as: .systemMedium) {
    YesWidget()
} timeline: {
    SimpleEntry(date: .now, phrase: "read a chapter of a book")
}

