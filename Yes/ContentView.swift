//
//  ContentView.swift
//  Yes
//
//  Created by justin casler on 2/9/25.
//

import SwiftUI
import UIKit

struct ContentView: View {
    @EnvironmentObject var viewModel: AuthViewModel

    var body: some View {
        Group {
            if viewModel.userSession != nil {
                // User is signed in. However, we wait until the full user data is available.
                if let user = viewModel.currentUser {
                    AuthenticatedContentView(user: user)
                } else {
                    // Optionally, show a loading indicator until user data is fetched.
                    ProgressView("Loading...")
                }
            } else {
                // Show the login screen if no user session exists.
                NavigationView {
                    LoginView()
                }
                .navigationViewStyle(StackNavigationViewStyle())
            }
        }
    }
}

struct AuthenticatedContentView: View {
    let user: User
    @State private var currentPage = 0
    
    var pages: [UIViewController] {
        [
            UIHostingController(rootView: HomeView(user: user)),
            UIHostingController(rootView: StreakView(user: user))
        ]
    }

    var body: some View {
        PageCurlView(currentPage: $currentPage, pages: pages)
            .edgesIgnoringSafeArea(.all)
    }
}

#Preview {
    ContentView().environmentObject(AuthViewModel())
}
