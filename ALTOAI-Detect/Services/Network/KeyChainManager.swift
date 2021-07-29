//
//  KeychainManager.swift
//  ALTOAI-Detect
//
//  Created by Volodymyr Grek on 27.07.2021.
//

import Foundation
import SimpleKeychain

class KeyChainManager {
    enum Key: String {
        case apiKey
        case secretKey
        case token
        case isSignedIn
    }
    static let shared: KeyChainManager = {
        return KeyChainManager()
    }()
    func getUserCredentials() -> (apiKey: String?, secretKey: String?) {
        let apiKey = A0SimpleKeychain().string(forKey: Key.apiKey.rawValue)
        let secretKey = A0SimpleKeychain().string(forKey: Key.secretKey.rawValue)
        return (apiKey, secretKey)
    }
    func setUserCredentials(apiKey: String, secretKey: String) {
        A0SimpleKeychain().setString(apiKey, forKey: Key.apiKey.rawValue)
        A0SimpleKeychain().setString(secretKey, forKey: Key.secretKey.rawValue)
    }
    func getToken() -> String? {
        return A0SimpleKeychain().string(forKey: Key.token.rawValue)
    }
    func setToken(token: String) {
        A0SimpleKeychain().setString(token, forKey: Key.token.rawValue)
    }
    func signInUser() {
        A0SimpleKeychain().setString("true", forKey: Key.isSignedIn.rawValue)
    }
    func signOutUser() {
        A0SimpleKeychain().setString("false", forKey: Key.isSignedIn.rawValue)
        A0SimpleKeychain().deleteEntry(forKey: Key.token.rawValue)
        A0SimpleKeychain().deleteEntry(forKey: Key.apiKey.rawValue)
        A0SimpleKeychain().deleteEntry(forKey: Key.secretKey.rawValue)
    }
    func isUserSignedIn() -> Bool {
        return A0SimpleKeychain().string(forKey: Key.isSignedIn.rawValue) == "true"
    }
    func signIn(apiKey: String, secretKey: String, token: String) {
        setUserCredentials(apiKey: apiKey, secretKey: secretKey)
        setToken(token: token)
        signInUser()
    }
}
