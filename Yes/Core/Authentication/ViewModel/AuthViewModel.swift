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
    @Published var userSession: FirebaseAuth.User?
    @Published var didAuthenticateUser = false
    @Published var currentUser: User?
    
    private var tempUserSession: FirebaseAuth.User?
    private let service = UserService()
    
    // Store the nonce used for Apple sign in.
    var currentNonce: String?
    
    init(){
        self.userSession = Auth.auth().currentUser
        self.fetchUser()
        print("authviewmodel user session :", self.userSession)
    }
    
    func signOut() {
        userSession = nil
        try? Auth.auth().signOut()
    }
    
    func fetchUser() {
        guard let uid = self.userSession?.uid else { return }
        service.fetchUser(withUid: uid) { user in
            self.currentUser = user
        }
        print("authviewmodel reroll :", uid, self.currentUser)
    }
    
    func backgroundFetchUser(completion: @escaping (User?) -> Void) {
        guard let uid = self.userSession?.uid else {
            completion(nil)
            return
        }
        service.fetchUser(withUid: uid) { user in
            self.currentUser = user
            completion(user)
        }
        print("authviewmodel reroll:", uid, self.currentUser)
    }
    
    // MARK: - Apple Sign In Integration
    
    /// Configure the Apple ID request with nonce and scopes.
    func configureAppleRequest(request: ASAuthorizationAppleIDRequest) {
        let nonce = randomNonceString()
        currentNonce = nonce
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
        print("Finished configuration")
    }
    
    /// Handle the result of the Apple sign in process.
    func signInWithApple(result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let auth):
            switch auth.credential {
            case let appleIDCredential as ASAuthorizationAppleIDCredential:
                guard let appleIDToken = appleIDCredential.identityToken else {
                    print("Unable to fetch identity token")
                    return
                }
                guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                    print("Unable to serialize token string from data")
                    return
                }
                
                let credential = OAuthProvider.appleCredential(
                    withIDToken: idTokenString,
                    rawNonce: currentNonce,
                    fullName: appleIDCredential.fullName
                )
                
                Auth.auth().signIn(with: credential) { [weak self] result, error in
                    if let error = error {
                        print("Firebase sign in error: \(error.localizedDescription)")
                        return
                    }
                    guard let user = result?.user else { return }
                    self?.userSession = user
                    
                    // Create a user document if needed using Apple credentials.
                    self?.createUserIfNeeded(user: user, appleCredential: appleIDCredential) {
                        self?.updateUserFCMTokenAndTimezone()
                        self?.fetchUser()
                        print("User signed in with Apple successfully")
                    }
                }
                
            default:
                print("Received unknown authorization credential type")
            }
        case .failure(let error):
            print("Sign in with Apple failed: \(error.localizedDescription)")
        }
    }
    
    /// Create a new Firestore user document for Apple sign in if one doesn’t exist.
    private func createUserIfNeeded(user: FirebaseAuth.User,
                                    appleCredential: ASAuthorizationAppleIDCredential,
                                    completion: @escaping () -> Void) {
        let docRef = Firestore.firestore().collection("users").document(user.uid)
        docRef.getDocument { document, error in
            if let document = document, document.exists {
                print("User document already exists.")
                completion()
            } else {
                let fullname = appleCredential.fullName?.formatted() ?? "User"
                let email = appleCredential.email ?? ""
                let jan1_2025 = Calendar.current.date(from: DateComponents(year: 2025, month: 1, day: 1))!
                let data: [String: Any] = [
                    "id": user.uid,
                    "fullName": fullname,
                    "email": email,
                    "streak": 1,
                    "phrases": [],
                    "rerolls": 1,
                    "rerollDate": Date(),
                    "lastSignIn": jan1_2025,
                    "done": false,
                    "fcmToken": Messaging.messaging().fcmToken ?? "",
                    "timezone": TimeZone.current.identifier,
                ]
                docRef.setData(data) { error in
                    if let error = error {
                        print("Error creating user document: \(error.localizedDescription)")
                    } else {
                        print("User document created successfully.")
                    }
                    completion()
                }
            }
        }
    }
    
    /// Create a new Firestore user document for phone sign in if one doesn’t exist.
    private func createUserIfNeededForPhone(user: FirebaseAuth.User,
                                            completion: @escaping () -> Void) {
        let docRef = Firestore.firestore().collection("users").document(user.uid)
        docRef.getDocument { document, error in
            if let document = document, document.exists {
                print("User document already exists.")
                completion()
            } else {
                let data: [String: Any] = [
                    "id": user.uid,
                    "fullName": "User",
                    "email": "",
                    "streak": 1,
                    "phrases": [],
                    "rerolls": 1,
                    "rerollDate": Date(),
                    "lastSignIn": Date(),
                    "done": false,
                    "fcmToken": Messaging.messaging().fcmToken ?? "",
                    "timezone": TimeZone.current.identifier,
                ]
                docRef.setData(data) { error in
                    if let error = error {
                        print("Error creating user document: \(error.localizedDescription)")
                    } else {
                        print("User document created successfully.")
                    }
                    completion()
                }
            }
        }
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
    func sendPhoneVerificationCode(phoneNumber: String, completion: @escaping (Bool) -> Void) {
        PhoneAuthProvider.provider().verifyPhoneNumber(phoneNumber, uiDelegate: nil) { verificationID, error in
            if let error = error {
                let nsError = error as NSError
                print("Error verifying phone number: \(nsError.localizedDescription)")
                print("Error code: \(nsError.code)")
                print("Error details: \(nsError.userInfo)")
                completion(false)
                return
            }
            if let verificationID = verificationID {
                UserDefaults.standard.set(verificationID, forKey: "authVerificationID")
                print("Verification code sent. Verification ID: \(verificationID)")
            } else {
                print("No verification ID received and no error reported.")
            }
            completion(true)
        }
    }

    /// Verify the SMS code entered by the user and create a user document if needed.
    func verifySMSCode(verificationCode: String, completion: @escaping (Bool) -> Void) {
        guard let verificationID = UserDefaults.standard.string(forKey: "authVerificationID") else {
            print("Missing verification ID.")
            completion(false)
            return
        }
        
        let credential = PhoneAuthProvider.provider().credential(
            withVerificationID: verificationID,
            verificationCode: verificationCode
        )
        
        Auth.auth().signIn(with: credential) { [weak self] result, error in
            if let error = error {
                print("Error signing in with phone auth: \(error.localizedDescription)")
                completion(false)
                return
            }
            guard let user = result?.user else {
                completion(false)
                return
            }
            self?.userSession = user
            
            // Create a user document for phone sign in if needed.
            self?.createUserIfNeededForPhone(user: user) {
                self?.updateUserFCMTokenAndTimezone()
                self?.fetchUser()
                print("User signed in with phone number successfully.")
                completion(true)
            }
        }
    }
}
