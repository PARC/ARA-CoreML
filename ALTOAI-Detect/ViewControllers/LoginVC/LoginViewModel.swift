//
//  LoginViewModel.swift
//  ALTOAI-Detect
//
//  Created by Volodymyr Grek on 28.07.2021.
//

import Foundation

class LoginViewModel {
    func login(apiKey: String, secretKey: String) {
        let parameters = ["grant_type": "client_credentials", "client_id": apiKey, "client_secret": secretKey]
        NetworkManager.shared.authorize(parameters: parameters) { (result) in
            switch result {
            case .success(let data):
                if let token = (try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any])?["access_token"] as? String {
                    UserDefaultsManager.shared.signIn(apiKey: apiKey, secretKey: secretKey, token: token)
                }
            case .failure(let error):
                print(error)
            }
        }
    }
}
