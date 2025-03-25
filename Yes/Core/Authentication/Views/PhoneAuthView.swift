//
//  PhoneAuthView.swift
//  Yes
//
//  Created by justin casler on 2/23/25.
//

import SwiftUI

struct PhoneAuthView: View {
    @EnvironmentObject var viewModel: AuthViewModel
    @State private var selectedCountryCode: String = "+1"
    @State private var phoneNumber: String = ""
    @State private var previousPhoneNumber: String = ""
    @State private var isCodeSent = false
    @State private var rawPhoneNumber: String = ""
    @State private var otpDigits: [String] = Array(repeating: "", count: 6)

    
    // List of country codes for the dropdown
    private let countryCodes = ["+1", "+44", "+91"]
    
    // Track which digit field is currently focused
    @FocusState private var focusedField: Int?
    // Focus state for the phone number text field
    @FocusState private var phoneNumberFieldFocused: Bool

    var body: some View {
        ZStack {
            // Background image covering the whole view
            Image("Paper")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                if !isCodeSent {
                    // Phone number input with centered country code picker and text field
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
                            .onChange(of: phoneNumber) { newValue, _ in
                                   // If deletion happened, just update previousPhoneNumber and do not reformat.
                                   if newValue.count < previousPhoneNumber.count {
                                       previousPhoneNumber = newValue
                                   } else {
                                       // Otherwise, reformat the string.
                                       let formatted = formatPhoneNumber(newValue)
                                       if formatted != newValue {
                                           phoneNumber = formatted
                                       }
                                       previousPhoneNumber = phoneNumber
                                   }
                               }
                    }
                    .padding()
                    .frame(maxWidth: 300)  // Constrain width to center the input
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.black, lineWidth: 1)
                    )
                    
                    // Extra spacing between input and button
                    Spacer().frame(height: 10)
                    
                    Button("Send Verification Code") {
                        // Prepend selected country code to the phone number
                        let fullPhoneNumber = "\(selectedCountryCode) \(phoneNumber)"
                        viewModel.sendPhoneVerificationCode(phoneNumber: fullPhoneNumber) { success in
                            if success {
                                isCodeSent = true
                                // Set focus to the first digit field when code is sent
                                focusedField = 0
                            }
                        }
                    }
                    .padding()
                    .frame(maxWidth: 300)
                    .background(Color.black)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                } else {
                    // Six individual rounded squares for code input
                    OTPTextField(numberOfFields: 6, enterValue: $otpDigits)
                                            .padding()
                    
                    Button("Verify Code") {
                        let verificationCode = otpDigits.joined()
                        viewModel.verifySMSCode(verificationCode: verificationCode) { success in
                            // Handle post-verification actions here.
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
        // Tap gesture to dismiss the keyboard on any background tap
        .background(
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    focusedField = nil
                    phoneNumberFieldFocused = false
                }
        )
    }
    
    /// Formats a given phone number string to the pattern (123) 123-1234.
    private func formatPhoneNumber(_ number: String) -> String {
        // Filter only digits from the input.
        let digits = number.filter { $0.isNumber }
        var result = ""
        let count = digits.count
        let array = Array(digits)
        
        if count > 0 {
            result.append("(")
            // Append up to 3 digits for the area code.
            for i in 0..<min(count, 3) {
                result.append(array[i])
            }
            if count >= 3 {
                result.append(") ")
            }
        }
        
        if count > 3 {
            // Append next 3 digits for the prefix.
            for i in 3..<min(count, 6) {
                result.append(array[i])
            }
        }
        
        if count > 6 {
            result.append("-")
            // Append up to 4 digits for the line number.
            for i in 6..<min(count, 10) {
                result.append(array[i])
            }
        }
        
        return result
    }
}

struct PhoneAuthView_Previews: PreviewProvider {
    static var previews: some View {
        PhoneAuthView()
            .environmentObject(AuthViewModel())
    }
}
