//
//  LoginView.swift
//  Vondera
//
//  Created by Shreif El Sayed on 01/06/2023.
//

import SwiftUI
import AlertToast

struct LoginView: View {
    @StateObject var viewModel = LoginViewModel()
    //@ObservedObject var appleAuth = AppleSignInHelper()
    
    @State var creatingAccount = false
    @State var forgetPassword = false
    @State var showSavedItems = false

    @Environment(\.colorScheme) var colorScheme
    @State var count = 0
    @State var authInfo:AuthProviderInfo?
    
    var body: some View {
        VStack(alignment: .center) {
            HStack {
                Text("Welcome Back !")
                    .font(.title2)
                    .bold()
                    .foregroundStyle(Color.accentColor)
                
                Spacer()
            }
            
            
            
            Spacer().frame(height: 24)
            
            VStack(spacing: 22) {
                FloatingTextField(title: "Email address", text: $viewModel.email, required: nil ,autoCapitalize: .never, keyboard: .emailAddress)
                
                FloatingTextField(title: "Password", text: $viewModel.password, required: nil, secure: true)
                
                ButtonLarge(label: "Sign in", action: callLogin)
                
                HStack {
                    Text("Forget Password ?")
                        .foregroundStyle(Color.accentColor)
                        .onTapGesture {
                            forgetPassword = true
                        }
                    Spacer()
                }
                
                
            }
            
            Spacer().frame(height: 14)
            
            HStack (spacing: 0) {
                Text("Don't have an account ? ")
                
                Text("Sign Up")
                    .bold()
                    .underline()
                    .foregroundStyle(Color.accentColor)
                    .onTapGesture {
                        creatingAccount = true
                    }
                
            }
                               
            
            
            Spacer()
            
            if count > 0 {
                Button("Or Login to saved account") {
                    showSavedItems = true
                }
                .bold()
                .padding(.vertical, 8)
            }
            
            
            VStack(alignment: .center) {
                Text("By signing in, you agree to our ")
                    .font(.system(size: 16))
                
                HStack(spacing:0) {
                    Text("Terms & Conditions")
                        .font(.system(size: 16))
                        .bold()
                        .foregroundStyle(Color.accentColor)
                        .underline()
                        .onTapGesture {
                            openTermsAndConditionsLink()
                        }
                    
                    Text(" and our ")
                        .font(.system(size: 16))
                    
                    Text("Privacy Policy")
                        .font(.system(size: 16))
                        .bold()
                        .foregroundStyle(Color.accentColor)
                        .underline()
                        .onTapGesture {
                            openPrivacyPolicyLink()
                        }
                }
            }
            
        }
        .padding()
        .navigationDestination(isPresented: $creatingAccount) {
            CreateAccountView(authInfo: authInfo)
        }
        .navigationDestination(isPresented: $forgetPassword) {
            ForgetPasswordView()
        }
        .sheet(isPresented: $showSavedItems) {
            SwitchAccountView(show: $showSavedItems)
        }
        .onAppear {
            Task {
                let savedUsers = SavedAccountManager().getAllUsers()
                count = savedUsers.count
            }
        }
    }
    
    func openTermsAndConditionsLink() {
        let url = "https://www.vondera.app/terms-conditions"
        if let Url = URL(string: url) {
            UIApplication.shared.open(Url)
        }
    }
    
    func openPrivacyPolicyLink() {
        let url = "https://www.vondera.app/privacy-policy"
        if let Url = URL(string: url) {
            UIApplication.shared.open(Url)
        }
    }
    
    
    func callLogin() {
        Task {
            await viewModel.login()
        }
    }
}


struct RoundedImageButton: View {
    var assetName = "apple.logo"
    var assetSize:CGFloat = 25
    var radius:CGFloat = 6
    var strokeColor:Color = Color.gray.opacity(0.5)
    var strokeWidth:CGFloat = 1
    
    var body: some View {
        RoundedRectangle(cornerRadius: radius)
            .stroke(strokeColor, lineWidth: strokeWidth)
            .overlay(
                Image(assetName)
                    .resizable()
                    .frame(width: assetSize)
                    .scaledToFit()
                    .padding(8)
            )
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
