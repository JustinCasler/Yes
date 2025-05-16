//
//  User.swift
//  Yes
//
//  Created by justin casler on 2/19/25.
//

import Firebase
import FirebaseFirestore

struct User: Identifiable, Decodable {
    @DocumentID var id: String?
    let fullName: String?
    var streak: Int
    var phrases: [Int]
    var rerolls: Int
    var rerollDate: Date
    var lastSignIn: Date
    var done: Bool
    var fcmToken: String?
    var timezone: String?
    var updatedPhraseDate: Date
}
