//
//  StreakViewModel.swift
//  Yes
//
//  Created by justin casler on 5/4/25.
//

import Foundation
import Combine
class StreakViewModel: ObservableObject {
    @Published var currentUser: User?
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setup()
    }
    private func setup(){
        UserService.shared.$currentUser.sink { [weak self] user in
            self?.currentUser = user
        }.store(in: &cancellables)
    }

}
