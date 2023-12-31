//
//  LoginViewModel.swift
//  Vondera
//
//  Created by Shreif El Sayed on 01/06/2023.
//

import Foundation
import FirebaseAuth

class LoginViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var errorMsg:String?
    
    let authManger:AuthManger
    
    init() {
        authManger = AuthManger()
    }
    
    func appleSignIn(cred:AuthCredential, id: String) async -> Bool {
        return await authManger.signUserWithApple(authCred: cred, appleId: id)
    }
    
    func fbSignIn(cred:AuthCredential, id: String) async -> Bool {
        return await authManger.signInWithFacebook(authCred: cred, fbId: id)
    }
    
    func googleSignIn(cred:AuthCredential, id: String) async -> Bool {
        return await authManger.signUserWithGoogle(authCred: cred, id: id)
    }
    
    func login() async -> Bool {
        guard validate() else {
            return false
        }
        
        let loggedIn = await authManger.signUserInViaMail(email: email, password: password)
        
        if loggedIn == false {
            errorMsg = "No user was found"
            return false
        }
        
        return true
    }
    
    func loginWithFacebook() async {
        
    }
    
    func validate() -> Bool {        
        guard !email.isBlank, !password.isBlank else {
            errorMsg = "Please fill in all fields"
            return false
        }
        
        guard email.isValidEmail else {
            errorMsg = "Please enter valid email"
            return false
        }
        
        guard password.count > 5 else {
            errorMsg = "Please enter valid password"
            return false
        }
        
        return true
    }
}
