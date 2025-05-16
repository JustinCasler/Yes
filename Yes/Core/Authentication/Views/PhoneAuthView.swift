//
//  PhoneAuthView.swift
//  Yes
//
//  Created by justin casler on 2/23/25.
//

import SwiftUI

struct PhoneAuthView: View {
    @Environment(\.dismiss) var dismiss
    @State private var selectedCountryCode: String = "+1"
    @State private var phoneNumber: String = ""
    @State private var previousPhoneNumber: String = ""
    @State private var isCodeSent = false
    @State private var rawPhoneNumber: String = ""
    @State private var otpDigits: [String] = Array(repeating: "", count: 6)
    
    private let countryCodes = ["+1", "+44", "+52", "+91", "+86", "+30", "+34", "+39", "+46", "+41", "+61", "62"]
    
    @FocusState private var focusedField: Int?
    @FocusState private var phoneNumberFieldFocused: Bool

    var body: some View {
        ZStack {
            Image("Paper")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                if !isCodeSent {
                    HStack(spacing: 10) {
                        Picker("Country Code", selection: $selectedCountryCode) {
                            ForEach(countryCodes, id: \.self) { code in
                                Text(code)
                                    .foregroundColor(.black)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .frame(maxWidth: 80)
                        .accentColor(.black)
                        .padding(.horizontal, -15)

                        TextField("", text: $phoneNumber, prompt: Text("Enter your phone number").foregroundColor(.black))
                            .keyboardType(.phonePad)
                            .foregroundColor(.black)
                            .font(.system(size: 16))
                            .onChange(of: phoneNumber) { newValue in
                                if newValue.count < previousPhoneNumber.count {
                                    previousPhoneNumber = newValue
                                } else {
                                    let formatted = formatPhoneNumber(newValue)
                                    if formatted != newValue {
                                        phoneNumber = formatted
                                    }
                                    previousPhoneNumber = phoneNumber
                                }
                            }
                    }
                    .padding()
                    .frame(maxWidth: 300)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.black, lineWidth: 1)
                    )

                    Spacer().frame(height: 10)

                    Button("Send Verification Code") {
                        let fullPhoneNumber = "\(selectedCountryCode) \(phoneNumber)"
                        AuthViewModel.shared.sendPhoneVerificationCode(phoneNumber: fullPhoneNumber) { success in
                            if success {
                                withAnimation {
                                    isCodeSent = true
                                    focusedField = 0
                                }
                            }
                        }
                    }
                    .padding()
                    .frame(maxWidth: 300)
                    .background(Color.black)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                } else {
                    OTPTextField(numberOfFields: 6, enterValue: $otpDigits)
                        .padding()

                    Button("Verify Code") {
                        let verificationCode = otpDigits.joined()
                        AuthViewModel.shared.verifySMSCode(verificationCode: verificationCode) { success in
                            if success {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                    dismiss()
                                }
                            }
                        }
                    }
                    .padding()
                    .frame(maxWidth: 300)
                    .background(Color.black)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
            }
            .padding()
        }
        .background(
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    focusedField = nil
                    phoneNumberFieldFocused = false
                }
        )
    }

    private func formatPhoneNumber(_ number: String) -> String {
        let digits = number.filter { $0.isNumber }
        var result = ""
        let count = digits.count
        let array = Array(digits)

        if count > 0 {
            result.append("(")
            for i in 0..<min(count, 3) {
                result.append(array[i])
            }
            if count >= 3 {
                result.append(") ")
            }
        }

        if count > 3 {
            for i in 3..<min(count, 6) {
                result.append(array[i])
            }
        }

        if count > 6 {
            result.append("-")
            for i in 6..<min(count, 10) {
                result.append(array[i])
            }
        }

        return result
    }
}
 
