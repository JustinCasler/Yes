//
//  UserService.swift
//  Celi
//
//  Created by justin casler on 3/6/24.
//

import Firebase
import FirebaseFirestore
import FirebaseAuth

class UserService {
    @Published var currentUser: User?
    
    static let shared = UserService()
    init() {
        Task { try await fetchUser()}
    }
    
    @MainActor
    func fetchUser() async {
      guard let uid = Auth.auth().currentUser?.uid else { return }
      do {
        let snapshot = try await Firestore.firestore()
                              .collection("users")
                              .document(uid)
                              .getDocument()
        // 1️⃣ Print the raw dictionary:
        if let raw = snapshot.data() {
          print("🔥 Raw user doc data:", raw)
        } else {
          print("⚠️ No data found for user \(uid)")
        }

        // 2️⃣ Then attempt to decode:
        let user = try snapshot.data(as: User.self)
        self.currentUser = user

      } catch {
        print("❌ fetchUser error:", error)
      }
    }
    
    func updateUser(_ user: User, completion: ((Error?) -> Void)? = nil) {
        guard let userID = user.id else {
            completion?(NSError(
                domain: "UserErrorDomain",
                code:   0,
                userInfo: [NSLocalizedDescriptionKey: "User ID is missing"]
            ))
            return
        }

        let db   = Firestore.firestore()
        let data: [String: Any] = [
            "fullName":          user.fullName,
            "streak":            user.streak,
            "phrases":           user.phrases,
            "rerolls":           user.rerolls,
            "rerollDate":        user.rerollDate,
            "lastSignIn":        user.lastSignIn,
            "done":              user.done,
            "fcmToken":          user.fcmToken ?? "",
            "timezone":          user.timezone ?? "",
            "updatedPhraseDate": user.updatedPhraseDate
        ]

        let docRef = db.collection("users").document(userID)
        docRef.updateData(data) { [weak self] error in
            if let error = error {
                completion?(error)
                return
            }
            // **Optimistically update in‑memory state** on the main actor:
            Task { @MainActor in
                self?.currentUser = user
                completion?(nil)
            }
        }
    }
     
}
