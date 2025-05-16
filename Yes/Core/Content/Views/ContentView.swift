//
//  ContentView.swift
//  Yes
//
//  Created by justin casler on 2/9/25.
//

import SwiftUI
import UIKit

struct ContentView: View {
    @StateObject var viewModel = ContentViewModel()
    @AppStorage("hasSeenWidgetInstructions") private var hasSeenWidgetInstructions = false
    private var currentUser: User? {
        return viewModel.currentUser
    }

    var body: some View {
        Group {
            if viewModel.userSession != nil {
                if let user = currentUser {
                    if !hasSeenWidgetInstructions {
                        WidgetInstructionsView {
                            hasSeenWidgetInstructions = true
                        }
                    } else {
                        AuthenticatedContentView(user: user)
                    }
                } else {
                    ProgressView("Loading...")
                }
            } else {
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
            UIHostingController(rootView: HomeView()),
            UIHostingController(rootView: StreakView())
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
