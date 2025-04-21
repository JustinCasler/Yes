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
    @AppStorage("hasSeenWidgetInstructions") private var hasSeenWidgetInstructions = false

    var body: some View {
        Group {
            if viewModel.userSession != nil {
                if let user = viewModel.currentUser {
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
