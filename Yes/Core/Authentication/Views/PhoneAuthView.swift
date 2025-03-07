//
//  PhoneAuthView.swift
//  Yes
//
//  Created by justin casler on 2/23/25.
//

import SwiftUI

struct PhoneAuthView: View {
    @EnvironmentObject var viewModel: AuthViewModel
    @State private var phoneNumber: String = ""
    @State private var verificationCode: String = ""
    @State private var isCodeSent = false

    var body: some View {
        VStack(spacing: 20) {
            if !isCodeSent {
                TextField("Enter your phone number", text: $phoneNumber)
                    .keyboardType(.phonePad)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
                    .padding(.horizontal)
                Button("Send Verification Code") {
                    viewModel.sendPhoneVerificationCode(phoneNumber: phoneNumber) { success in
                        if success {
                            isCodeSent = true
                        }
                    }
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            } else {
                TextField("Enter verification code", text: $verificationCode)
                    .keyboardType(.numberPad)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
                    .padding(.horizontal)
                Button("Verify Code") {
                    viewModel.verifySMSCode(verificationCode: verificationCode) { success in
                        // Handle post-verification UI or navigation here.
                    }
                }
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
        }
        .padding()
    }
}

struct PhoneAuthView_Previews: PreviewProvider {
    static var previews: some View {
        PhoneAuthView()
            .environmentObject(AuthViewModel())
    }
}
