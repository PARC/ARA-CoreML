//
//  AccessToken.swift
//  ALTOAI-Detect
//
//  Created by Volodymyr Grek on 29.07.2021.
//

import Foundation

struct AccessToken: Decodable {
  let accessToken: String
  let expiresIn: Int

  enum CodingKeys: String, CodingKey {
    case accessToken = "access_token"
    case expiresIn = "expires_in"
  }
}
