//
//  APIRouter.swift
//  ALTOAI-Detect
//
//  Created by Volodymyr Grek on 20.07.2021.
//

import Foundation
import Alamofire

enum APIRouter: APIConfiguration {
    
    case login(username:String, password:String)
    //case getUserDetails
  
    
    // MARK: - HTTPMethod
    var method: HTTPMethod {
        switch self {
        case .login:
            return .post
//        case .getUserDetails:
//            return .get
        }
    }
    // MARK: - Parameters
     var parameters: RequestParams {
        switch self {
        case .login(let client_id, let password):
            return .body(["client_id":client_id,"password":password])
//        case .getUserDetails:
//            return.body([:])
        }
    }
    
    // MARK: - Path
    var path: String {
        switch self {
        case .login:
            return "/auth"
//        case .getUserDetails:
//            return "/userDetailEndpoint"
        }
    }
    
    // MARK: - URLRequestConvertible
    func asURLRequest() throws -> URLRequest {
        let url = try Constants.ProductionServer.baseURL.asURL()
        
        var urlRequest = URLRequest(url: url.appendingPathComponent(path))
        
        // HTTP Method
        urlRequest.httpMethod = method.rawValue
        
        // Common Headers
        urlRequest.setValue(ContentType.json.rawValue, forHTTPHeaderField: HTTPHeaderField.acceptType.rawValue)
        urlRequest.setValue(ContentType.json.rawValue, forHTTPHeaderField: HTTPHeaderField.contentType.rawValue)
        
        // Parameters
        switch parameters {
            
        case .body(let params):
            urlRequest.httpBody = try JSONSerialization.data(withJSONObject: params, options: [])
            
        case .url(let params):
                let queryParams = params.map { pair  in
                    return URLQueryItem(name: pair.key, value: "\(pair.value)")
                }
                var components = URLComponents(string:url.appendingPathComponent(path).absoluteString)
                components?.queryItems = queryParams
                urlRequest.url = components?.url
        }
            return urlRequest
    }
}
