//
//  LoginView.swift
//  Yes
//
//  Created by justin casler on 2/11/25.
//

// LoginView.swift

import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @EnvironmentObject var viewModel: AuthViewModel
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    var body: some View {
        ZStack {
            if horizontalSizeClass == .regular {
                // Layout for iPad or larger screens
                Image("Marble_Background")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                Image("Composition_Notebook")
                    .resizable()
                    .scaledToFit()
                    .ignoresSafeArea()
            } else {
                // Layout for iPhones (compact size)
                Image("Composition_Notebook")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
            }
            VStack {
                Spacer() // Push content down
                
                VStack(spacing: 20) {
                    
                    // Sign In with Apple Button using the view model’s configuration and sign in handling.
                    SignInWithAppleButton(
                        onRequest: { request in
                            viewModel.configureAppleRequest(request: request)
                        },
                        onCompletion: { result in
                            viewModel.signInWithApple(result: result)
                        }
                    )
                    .signInWithAppleButtonStyle(.white)
                    .frame(height: 50)
                    .cornerRadius(10)
                    .padding(.horizontal, 50)
                    
                    NavigationLink(destination: PhoneAuthView().environmentObject(viewModel)) {
                        HStack {
                            Image(systemName: "phone.fill")
                            Text("Sign in with Phone Number")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .foregroundColor(.black)
                        .background(Color.white)
                        .cornerRadius(10)
                    }
                    .padding(.horizontal, 50)
                }
                .padding(.bottom, 150)
            }
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
            .environmentObject(AuthViewModel())
    }
}
