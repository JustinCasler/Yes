//
//  StreakView.swift
//  Yes
//
//  Created by justin casler on 2/16/25.
//

import SwiftUI

struct StreakView: View {
    let user: User
    @State private var streakCount = 54
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
    }
}
/*
#Preview {
    StreakView()
}
*/
