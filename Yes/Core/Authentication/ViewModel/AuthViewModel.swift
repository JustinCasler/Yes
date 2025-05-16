//
//  AuthViewModel.swift
//  Yes
//
//  Created by justin casler on 2/20/25.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth
import AuthenticationServices
import CryptoKit
import FirebaseMessaging

class AuthViewModel: ObservableObject {
    static let shared = AuthViewModel()
    @Published var userSession: FirebaseAuth.User?
    @Published var showDeleteAccountError = false
    @Published var deleteAccountErrorMessage = ""
    // Store the nonce used for Apple sign in.
    var currentNonce: String?
    
    init(){
        self.userSession = Auth.auth().currentUser
    }
    
    func signOut() {
        userSession = nil
        try? Auth.auth().signOut()
    }
    
    func deleteAccount() {
            guard let user = Auth.auth().currentUser else {
                print("No authenticated user to delete.")
                return
            }
            let uid = user.uid
            let db = Firestore.firestore()

            // 1) Delete the Firestore document
            db.collection("users").document(uid).delete { [weak self] error in
                if let error = error {
                    print("Error deleting Firestore user doc:", error.localizedDescription)
                    return
                }

                // 2) Delete the Auth user
                user.delete { error in
                    if let nsErr = error as NSError?,
                         nsErr.code == AuthErrorCode.requiresRecentLogin.rawValue {
                        DispatchQueue.main.async {
                            self?.deleteAccountErrorMessage = "To delete your account, please sign in again and then retry."
                            self?.showDeleteAccountError = true
                        }
                        return
                      }

                    // 3) Clean up local state
                    DispatchQueue.main.async {
                        self?.signOut()
                    }
                }
            }
        }
    
    
    // MARK: - Apple Sign In Integration
    
    /// Configure the Apple ID request with nonce and scopes.
    func configureAppleRequest(request: ASAuthorizationAppleIDRequest) {
        let nonce = randomNonceString()
        currentNonce = nonce
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
    }
    
    /// Handle the result of the Apple sign in process.
    func signInWithApple(result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let auth):
            guard let appleIDCredential = auth.credential as? ASAuthorizationAppleIDCredential else {
                print("Received unknown authorization credential type")
                return
            }
            guard
                let appleIDToken = appleIDCredential.identityToken,
                let idTokenString = String(data: appleIDToken, encoding: .utf8)
            else {
                print("Unable to fetch or serialize identity token")
                return
            }

            let credential = OAuthProvider.appleCredential(
                withIDToken:    idTokenString,
                rawNonce:       currentNonce,
                fullName:       appleIDCredential.fullName
            )

            Auth.auth().signIn(with: credential) { [weak self] authResult, error in
                guard let self = self else { return }
                if let error = error {
                    print("Firebase sign in error: \(error.localizedDescription)")
                    return
                }
                guard let firebaseUser = authResult?.user else {
                    print("No user returned from Firebase after sign‑in")
                    return
                }

                // Kick off an async task to write your Firestore document and update token/timezone.
                Task {
                    do {
                        // 1) Ensure your createUserIfNeeded is async throws
                        try await self.createUserIfNeeded(user: firebaseUser,
                                                          appleCredential: appleIDCredential)

                        // 2) Ensure updateUserFCMTokenAndTimezone is async throws too
                        try await self.updateUserFCMTokenAndTimezone()

                        // 3) Only now publish the session on the main actor
                        await MainActor.run {
                            self.userSession = firebaseUser
                        }
                        print("✅ User signed in and Firestore sync complete")

                    } catch {
                        print("❌ post‑sign‑in flow failed:", error)
                    }
                }
            }

        case .failure(let error):
            print("Sign in with Apple failed: \(error.localizedDescription)")
        }
    }

    
    /// Create a new Firestore user document for Apple sign in if one doesn’t exist.
    private func createUserIfNeeded(user: FirebaseAuth.User,
                                    appleCredential: ASAuthorizationAppleIDCredential) async throws {
        let docRef = Firestore.firestore()
                             .collection("users")
                             .document(user.uid)
        
        // Firestore’s async API:
        let snapshot = try await docRef.getDocument()
        if snapshot.exists {
            print("User document already exists.")
            return
        }
        
        let fullname = appleCredential.fullName?.formatted() ?? "User"
        let email    = appleCredential.email ?? ""
        let jan1_2025 = Calendar.current
                             .date(from: DateComponents(year: 2025, month: 1, day: 1))!
        
        let data: [String: Any] = [
            "id":                user.uid,
            "fullName":          fullname,
            "streak":            1,
            "phrases":           [],
            "rerolls":           1,
            "rerollDate":        Date(),
            "lastSignIn":        jan1_2025,
            "done":              false,
            "fcmToken":          Messaging.messaging().fcmToken ?? "",
            "timezone":          TimeZone.current.identifier,
            "updatedPhraseDate": jan1_2025
        ]
        
        try await docRef.setData(data)
        print("User document created successfully.")
    }
    
    /// Create a new Firestore user document for phone sign in if one doesn’t exist.
    private func createUserIfNeededForPhone(user: FirebaseAuth.User) async throws {
        let docRef = Firestore.firestore()
                             .collection("users")
                             .document(user.uid)
        
        let snapshot = try await docRef.getDocument()
        if snapshot.exists {
            print("User document already exists.")
            return
        }
        
        let jan1_2025 = Calendar.current
                             .date(from: DateComponents(year: 2025, month: 1, day: 1))!
        let data: [String: Any] = [
            "id":                user.uid,
            "fullName":          "User",
            "email":             "",
            "streak":            1,
            "phrases":           [],
            "rerolls":           1,
            "rerollDate":        Date(),
            "lastSignIn":        Date(),
            "done":              false,
            "fcmToken":          Messaging.messaging().fcmToken ?? "",
            "timezone":          TimeZone.current.identifier,
            "updatedPhraseDate": jan1_2025
        ]
        
        try await docRef.setData(data)
        print("User document created successfully.")
    }

    
    // MARK: - Update FCM Token & Timezone After Login
    func updateUserFCMTokenAndTimezone() {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        
        let fcmToken = Messaging.messaging().fcmToken ?? ""
        let timezone = TimeZone.current.identifier
        let db = Firestore.firestore()
        db.collection("users").document(userID).updateData([
            "fcmToken": fcmToken,
            "timezone": timezone
        ]) { error in
            if let error = error {
                print("Error updating FCM token & timezone:", error.localizedDescription)
            } else {
                print("FCM token & timezone updated successfully.")
            }
        }
    }
    
    // MARK: - Utility Functions for Nonce Generation and Hashing
    
    func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] =
            Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        
        while remainingLength > 0 {
            let randoms: [UInt8] = (0 ..< 16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
                }
                return random
            }
            
            randoms.forEach { random in
                if remainingLength == 0 {
                    return
                }
                
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        return result
    }
    
    func sha256(_ input: String) -> String {
        guard let inputData = input.data(using: .utf8) else { return "" }
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
        
        return hashString
    }
    
    // MARK: - Phone Number Authentication
    func sendPhoneVerificationCode(phoneNumber: String,
                                   completion: @escaping (Bool) -> Void) {
        PhoneAuthProvider.provider()
            .verifyPhoneNumber(phoneNumber, uiDelegate: nil) { id, error in
          if let error = error {
            print("Error verifying phone number:", error.localizedDescription)
            return completion(false)
          }
          if let id = id {
            UserDefaults.standard.set(id, forKey: "authVerificationID")
            print("Verification code sent. ID:", id)
          }
          completion(true)
        }
    }

    /// Verify the SMS code entered by the user and create a user document if needed.
    func verifySMSCode(verificationCode: String,
                       completion: @escaping (Bool) -> Void) {
        guard let verificationID = UserDefaults
                .standard
                .string(forKey: "authVerificationID") else {
          print("Missing verification ID.")
          return completion(false)
        }

        let credential = PhoneAuthProvider.provider()
            .credential(
              withVerificationID: verificationID,
              verificationCode: verificationCode
            )

        Auth.auth().signIn(with: credential) { [weak self] result, error in
          guard let self = self else { return }
          if let error = error {
            print("Phone auth sign‑in error:", error.localizedDescription)
            return completion(false)
          }
          guard let firebaseUser = result?.user else {
            print("No user returned from phone sign‑in")
            return completion(false)
          }

          // 🚀 only now do we write the Firestore doc, update FCM/timezone, and THEN set userSession
          Task {
            do {
              try await self.createUserIfNeededForPhone(user: firebaseUser)
              try await self.updateUserFCMTokenAndTimezone()
              await MainActor.run {
                self.userSession = firebaseUser
              }
              print("✅ User signed in with phone number successfully.")
              completion(true)

            } catch {
              print("❌ post‑phone‑sign‑in flow failed:", error)
              completion(false)
            }
          }
        }
    }
}
