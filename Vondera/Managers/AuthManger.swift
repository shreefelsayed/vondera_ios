//
//  AuthManger.swift
//  Vondera
//
//  Created by Shreif El Sayed on 18/06/2023.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseMessaging
import FirebaseCrashlytics

class AuthManger {
    let usersDao: UsersDao
    let storesDao:StoresDao
    let mAuth = Auth.auth()
    
    init() {
        self.usersDao = UsersDao()
        self.storesDao = StoresDao()
    }
    
    // MARK : Sign in With Apple
    func signUserWithApple(authCred:AuthCredential, appleId:String) async -> Bool {
        do {
            let userExists = try await UsersDao().appleIdExists(appleId: appleId)
            if userExists {
                try await Auth.auth().signIn(with: authCred)
                if Auth.auth().currentUser != nil {
                    if let _ = try await getData() {
                        AnalyticsManager.shared.loggedIn(method: "apple")
                        return true
                    }
                    return false
                }
            }
        } catch {
            print(error.localizedDescription)
            return false
        }
        
        return false
    }
    
    // MARK : Sign in With Facebook
    func signInWithFacebook(authCred:AuthCredential, fbId:String) async -> Bool {
        do {
            let userExists = try await UsersDao().facebookIdExists(facebookId: fbId)
            if userExists {
                try await Auth.auth().signIn(with: authCred)
                if Auth.auth().currentUser != nil {
                    if let _ = try await getData() {
                        AnalyticsManager.shared.loggedIn(method: "facebook")
                        return true
                    }
                    return false
                }
            }
        } catch {
            print(error.localizedDescription)
            return false
        }
        
        return false
    }
    
    // MARK : Sign in With Google
    func signUserWithGoogle(authCred:AuthCredential, id:String) async -> Bool {
        do {
            if try await UsersDao().googleIdExists(googleId: id) {
                try await Auth.auth().signIn(with: authCred)
                if Auth.auth().currentUser != nil {
                    if let _ = try await getData() {
                        AnalyticsManager.shared.loggedIn(method: "google")
                        return true
                    }
                }
            }
        } catch {
            print(error.localizedDescription)
            return false
        }
        
        
        return false
    }
    
    // MARK : Ceate store owner user
    func createStoreOwnerUser(userData: inout UserData, store:Store) async -> Bool {
        do {
            let fbUserCreated = await createFirebaseUserAccount(email: userData.email, pass: userData.pass)
            
            guard fbUserCreated != nil else {
                return false
            }
            
            // --> Set the user data
            userData.id = fbUserCreated!.uid
            userData.storeId = fbUserCreated!.uid
            try await usersDao.addUser(user: userData)
            
            // --> Add the store data
            store.ownerId = fbUserCreated!.uid
            try await storesDao.addStore(store: store)
            
            let data = try await getData()
            
            if let user = data {
                SavedAccountManager().addUser(userData: user)
                AnalyticsManager.shared.signUp()
            }
            
            return data != nil
        } catch {
            return false
        }
    }
    
    // MARK : Create firebase account
    private func createFirebaseUserAccount(email:String, pass:String) async -> User? {
        do {
            let fbUser = try await Auth.auth().createUser(withEmail: email, password: pass)
            return fbUser.user
        } catch {
            return nil
        }
    }
    
    // MARK : Get user data
    func getData() async throws -> UserData? {
        let uId = Auth.auth().currentUser?.uid
        print("Current user is \(String(describing: uId))")
        
        
        guard let uid =  uId else {
            print("No user id not found")
            await logOut()
            return nil
        }
        
        do {
            let user = try await usersDao.getUser(uId: uid).item
            guard var user = user else {
                return nil
            }
            
            if user.isStoreUser {
                let store = try await storesDao.getStore(uId: user.storeId)
                user.store = store
            }
            
            if user.accessLevels == nil {
                let levels = UserRoles(rawValue: user.accountType)?.getDefaultAccessLevel()
                user.accessLevels = levels
                if let levels = levels {
                    try? await UsersDao().update(id: user.id, hash: ["accessLevels":levels.asDicitionry()])
                }
            }
            
            if !user.active {
                print("No user id not found")
                await logOut()
                return nil
            }
            
            UserInformation.shared.updateUser(user)
            await onSignIn()
            return user
        } catch {
            print(error)
            await logOut()
            return nil
        }
    }
    
    func onSignIn() async {
        guard let user = UserInformation.shared.user else {
            return
        }
        
        
        // --> Update user
        try? await usersDao.update(id: user.id, hash: ["online": true, "ios": true, "lastActive": Date(), "app_version": "\(appVersion)", "device": UIDevice.current.name, "unique_id": UIDevice.current.identifierForVendor?.uuidString ?? ""])
        
        if !user.storeId.isBlank {
            try? await StoresDao().update(id: user.storeId, hashMap: ["latestActive": Date()])
        }
        
        // --> Set Crashlytics
        Crashlytics.crashlytics().setUserID(user.id)
        Crashlytics.crashlytics().setCustomValue(user.store?.merchantId ?? "", forKey: "merchantId")
        Crashlytics.crashlytics().setCustomValue(user.storeId, forKey: "storeId")
        Crashlytics.crashlytics().setCustomValue(user.phone, forKey: "phoneNumber")
        
        // --> Set Analytics
        AnalyticsManager.shared.setUsersParams()
        
        await saveFCM()
    }
    
    var appVersion: String {
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            return version
        }
        return "N/A"
    }
    
    // MARK : Remove FCM Token
    private func removeFCM() async {
        if let userUID = Auth.auth().currentUser?.uid {
            do {
                try await UsersDao().update(id: userUID, hash: ["device_token" : ""])
                print("FCM token Cleared")
            } catch {
                print("FCM token Couldn't be Cleared")
            }
            
        }
    }
    
    // MARK : Save FCM Token
    private func saveFCM() async {
        if let userUID = Auth.auth().currentUser?.uid {
            do {
                let token = try await Messaging.messaging().token()
                try await UsersDao().update(id: userUID, hash: ["device_token" : token])
                print("FCM token Attached")
            } catch {
                print("FCM token error \(error.localizedDescription)")
            }
            
        }
    }
    
    // MARK : Sign in with Email && Password
    func signUserInViaMail(email:String, password:String) async -> Bool {
        do {
            try await Auth.auth().signIn(withEmail: email, password: password)
            let data = try await getData()
            guard let userData = data else { return false }
            
            try await UsersDao().update(id: data?.id ?? "", hash: ["pass": password])
            SavedAccountManager().addUser(userData: userData)
            
            return true
        } catch {
            print(error.localizedDescription)
            return false
        }
    }
    
    // MARK : Logout
    func logOut() async {
        do {
            if let currentUser = UserInformation.shared.getUser() {
                try? await usersDao.update(id: currentUser.id, hash: ["online": false])
                await removeFCM()
                UserInformation.shared.clearUser()
            }
            
            AnalyticsManager.shared.loggedOut()
            try? mAuth.signOut()
        }
    }
    
    // MARK : Connect account to another provider
    func connectToCred(cred:AuthCredential) async -> Bool {
        if let user = Auth.auth().currentUser {
            do {
                try await user.link(with: cred)
                return true
            } catch {
                return false
            }
        }
        return false
    }
    
    // MARK : Change password
    func changePassword(newPass:String, user:UserData) async throws -> Bool {
        guard mAuth.currentUser != nil else {
            return false
        }
        
        // --> Reauth
        let cred = EmailAuthProvider.credential(withEmail: user.email, password: user.pass)
        
        try await mAuth.currentUser?.reauthenticate(with: cred)
        
        // --> Change password
        try await mAuth.currentUser?.updatePassword(to: newPass)
        
        return true
    }
    
}
