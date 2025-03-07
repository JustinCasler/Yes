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
        let db = Firestore.firestore()
        let data: [String: Any] = [
            "rerolls": user.rerolls,
            "rerollDate": user.rerollDate,
            "lastSignIn": user.lastSignIn,
            "phrases": user.phrases,
            "done": user.done
        ]
        
        db.collection("users").document(user.id!).updateData(data) { error in
            completion?(error)
        }
    }

}
