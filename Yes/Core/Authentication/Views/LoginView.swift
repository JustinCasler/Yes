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
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                if horizontalSizeClass == .regular {
                    Image("Marble_Background")
                        .resizable()
                        .scaledToFill()
                        .ignoresSafeArea()
                    Image("Composition_Notebook")
                        .resizable()
                        .scaledToFit()
                        .ignoresSafeArea()
                } else {
                    Image("Composition_Notebook")
                        .resizable()
                        .scaledToFill()
                        .ignoresSafeArea()
                }

                VStack {
                    Spacer()
                    VStack(spacing: 20) {
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

                        Button {
                            path.append("phoneAuth")
                        } label: {
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
            .navigationDestination(for: String.self) { value in
                if value == "phoneAuth" {
                    PhoneAuthView()
                        .environmentObject(viewModel)
                }
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
