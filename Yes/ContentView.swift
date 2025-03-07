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
            if let user = viewModel.currentUser { // Unwrapping the user
                AuthenticatedContentView(user: user)
            } else {
                // Show the login screen if not signed in.
                NavigationView {
                    LoginView()
                }
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
