//
//  ContentViewModel.swift
//  Yes
//
//  Created by justin casler on 5/5/25.
//

import Foundation
import Combine
import FirebaseAuth

class ContentViewModel: ObservableObject {
    @Published var userSession: FirebaseAuth.User?
    @Published var currentUser: User?

    private var cancallables = Set<AnyCancellable>()
    
    init() {
        setupSession()
        setupUser()
    }
    
    private func setupSession() {
        AuthViewModel.shared.$userSession.sink { [weak self] userSession in
            self?.userSession = userSession
            Task {
                do {
                    try await UserService.shared.fetchUser()
                } catch {
                    print("❌ failed to fetch user:", error)
                }
            }
        }.store(in: &cancallables)
    }
    
    private func setupUser() {
        UserService.shared.$currentUser.sink { [weak self] user in
            self?.currentUser = user
        }.store(in: &cancallables)
    }
}
