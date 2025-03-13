//
//  UserService.swift
//  Celi
//
//  Created by justin casler on 3/6/24.
//

import Firebase
import FirebaseFirestore

struct UserService {
    func fetchUser(withUid uid: String, completion: @escaping (User) -> Void) {
        Firestore.firestore().collection("users")
            .document(uid)
            .getDocument{snapshot, _ in
                guard let snapshot = snapshot else {return}
                
                guard let user = try? snapshot.data(as: User.self) else {return}
                
                completion(user)
            }
    }
    
    func updateUser(_ user: User, completion: ((Error?) -> Void)? = nil) {
        guard let userID = user.id else {
            completion?(NSError(domain: "UserErrorDomain", code: 0, userInfo: [NSLocalizedDescriptionKey: "User ID is missing"]))
            return
        }
        
        let db = Firestore.firestore()
        let data: [String: Any] = [
            "fullName": user.fullName,
            "streak": user.streak,
            "phrases": user.phrases,
            "rerolls": user.rerolls,
            "rerollDate": user.rerollDate,
            "lastSignIn": user.lastSignIn,
            "done": user.done,
            "fcmToken": user.fcmToken ?? "",
            "timezone": user.timezone ?? "",
            "updatedPhraseDate": user.updatedPhraseDate
        ]
        
        db.collection("users").document(userID).updateData(data) { error in
            completion?(error)
        }
    }

}
