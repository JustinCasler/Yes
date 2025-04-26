//
//  StreakView.swift
//  Yes
//
//  Created by justin casler on 2/16/25.
//

import SwiftUI

struct StreakView: View {
    let user: User
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showDeleteConfirmation = false

    init(user: User) {
        self.user = user
    }

    var body: some View {
        VStack {
            TallyMarksView(count: user.streak)
            Spacer()
        }
        .padding(10)
        .background(
            Image("Paper")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
        )
        // overlay the ellipsis menu in the top-trailing corner
        .overlay(alignment: .topTrailing) {
            Menu {
                Button("Sign Out", role: .none) {
                    authViewModel.signOut()
                }
                Button("Delete Account", role: .destructive) {
                    showDeleteConfirmation = true
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.title2)
                    .padding()
            }
        }
        // optional confirmation dialog before deleting
        .confirmationDialog(
            "Are you sure you want to delete your account?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete Account", role: .destructive) {
                authViewModel.deleteAccount() // or your own delete logic
            }
            Button("Cancel", role: .cancel) { }
        }
        .alert(
          "Couldn’t Delete Account",
          isPresented: $authViewModel.showDeleteAccountError,
          actions: {
            Button("OK", role: .cancel) { }
          },
          message: {
            Text(authViewModel.deleteAccountErrorMessage)
          }
        )
    }
}

/*
#Preview {
    StreakView()
}
*/
