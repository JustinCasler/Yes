//
//  YesApp.swift
//  Yes
//
//  Created by justin casler on 2/9/25.
//

import SwiftUI
import FirebaseCore
import UserNotifications
import FirebaseMessaging
import FirebaseAuth
import WidgetKit

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        FirebaseApp.configure()
        
        // Set up notifications
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        center.requestAuthorization(options: authOptions) { granted, error in
            if let error = error {
                print("Error requesting notifications permission: \(error.localizedDescription)")
            }
        }
        
        application.registerForRemoteNotifications()
        
        // Set Firebase Messaging delegate
        Messaging.messaging().delegate = self
        
        return true
    }
    
    // Called when APNs assigns a device token to the app.
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken

        Messaging.messaging().token { token, error in
            if let error = error {
                print("❌ Error fetching FCM token: \(error.localizedDescription)")
            } else if let token = token {
                print("✅ FCM Token received: \(token)")
            }
        }
    }
    
    // Called when Firebase Messaging receives a new token.
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("messaging")
        guard let newToken = fcmToken else { return }
        
        // Example: Assume you have an instance of your current user accessible through a shared AuthViewModel or similar.
        // Replace "currentUser" with however you access your user object.
        if var currentUser = UserService.shared.currentUser {
            // Update the user model with the new token.
            currentUser.fcmToken = newToken
            
            // Now update the user in your backend/database.
            UserService.shared.updateUser(currentUser) { error in
                if let error = error {
                    print("Error updating user with new fcmToken: \(error.localizedDescription)")
                } else {
                    print("User updated with new fcmToken.")
                }
            }
        } else {
            print("No current user available to update the fcmToken.")
        }
    }
    
    // Handle notifications when the app is in the foreground.
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .badge])
    }
    
    // Handle silent push notifications to trigger background updates.
    func application(_ application: UIApplication,
                     didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        // Forward the notification to Firebase Auth.
        let firebaseAuthHandled = Auth.auth().canHandleNotification(userInfo)
        if firebaseAuthHandled {
            print("Notification handled by Firebase Auth.")
        }
        
        // Now check if it's a silent push for your daily update.
        if let _ = userInfo["dailyRefresh"] as? String {
            print("✅ Silent push recognized, handling update...")
            BackgroundTaskManager.shared.handleSilentPush()
        } else {
            print("❌ Notification received, but not recognized as silent push")
        }
        
        completionHandler(.newData)
    }

}

class BackgroundTaskManager {
    static let shared = BackgroundTaskManager()

    /// Handles the background update when a silent push is received.
    func handleSilentPush() {
        updateDailyData()
    }
    
    /// Your daily update logic goes here. In this example, we simulate an update and reload widget timelines.
    func updateDailyData() {
        
        // Only run update logic if a Firebase user is logged in.
        guard Auth.auth().currentUser != nil else {
            print("No logged-in user, skipping update.")
            return
        }
        
        
        if var currentUser = UserService.shared.currentUser {
            
            // Check if updatedPhraseDate is already today.
            
            if Calendar.current.isDateInToday(currentUser.updatedPhraseDate) {
                print("User's updatedPhraseDate is already today. Skipping daily update.")
                return
            }
            
            // Run the daily update function.
            PhraseUpdater.updateForNewDay(user: &currentUser)
            
            currentUser.updatedPhraseDate = Date()
            UserService.shared.updateUser(currentUser) { error in
                if let e = error { print(e) }
            }

            // 3) (Optionally) reload widgets again if needed
            WidgetCenter.shared.reloadTimelines(ofKind: "YesWidget")
        }
    }
}

@main
struct YesApp: App {
    @StateObject var viewModel = AuthViewModel()
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
        }
    }
}
