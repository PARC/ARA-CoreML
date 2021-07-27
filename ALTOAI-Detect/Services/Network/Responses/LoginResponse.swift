//
//  LoginResponse.swift
//  ALTOAI-Detect
//
//  Created by Volodymyr Grek on 20.07.2021.
//

import Foundation

struct LoginResponse : Codable {
   
    let token : String?
    
    enum CodingKeys: String, CodingKey {
        case token = "access_token"
    }
}
