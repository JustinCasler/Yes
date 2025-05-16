//
//  StreakView.swift
//  Yes
//
//  Created by justin casler on 2/16/25.
//

import SwiftUI

struct StreakView: View {
    @StateObject var viewModel = StreakViewModel()
    @StateObject private var authVM = AuthViewModel.shared
    @State private var showDeleteConfirmation = false

    private var currentUser: User? {
        return viewModel.currentUser
    }

    var body: some View {
        VStack {
            TallyMarksView(count: currentUser?.streak ?? 0)
            Spacer()
        }
        .padding(10)
        .background(
            Image("Paper")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
        )
        .overlay(alignment: .topTrailing) {
            Menu {
                Button("Sign Out", role: .none) {
                    AuthViewModel.shared.signOut()
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
        .confirmationDialog(
            "Are you sure you want to delete your account?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete Account", role: .destructive) {
                authVM.deleteAccount()
            }
            Button("Cancel", role: .cancel) { }
        }
        .alert(
          "Couldn’t Delete Account",
          isPresented: $authVM.showDeleteAccountError,
          actions: {
            Button("OK", role: .cancel) { }
          },
          message: {
            Text(authVM.deleteAccountErrorMessage)
          }
        )
    }
}

/*
#Preview {
    StreakView()
}
*/
