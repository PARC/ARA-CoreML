//
//  APIConfiguration.swift
//  ALTOAI-Detect
//
//  Created by Volodymyr Grek on 20.07.2021.
//

import Foundation
import Alamofire

protocol APIConfiguration: URLRequestConvertible {
    var method: HTTPMethod { get }
    var path: String { get }
    var parameters: RequestParams { get }
}
