//
//  Constants.swift
//  ALTOAI-Detect
//
//  Created by Volodymyr Grek on 20.07.2021.
//

import Foundation
import Alamofire

struct Constants {
    struct ProductionServer {
        static let baseURL = "https://gateway-demo.qa.alto-platform.ai/api"
    }
    struct QA1Server {
        static let baseURL = "https://gateway-qa1.qa.alto-platform.ai/api"
    }
    struct QA2Server {
        static let baseURL = "https://gateway-qa2.qa.alto-platform.ai/api"
    }
}

enum HTTPHeaderField: String {
    case authentication = "Authorization"
    case contentType = "Content-Type"
    case acceptType = "Accept"
    case acceptEncoding = "Accept-Encoding"
    case string = "String"
    
}

enum ContentType: String {
    case json = "Application/json"
    case formEncode = "application/x-www-form-urlencoded"
}

enum RequestParams {
    case body(_:Parameters)
    case url(_:Parameters)
}
