//
//  NetworkManager+RequestInterceptor.swift
//  ALTOAI-Detect
//
//  Created by Volodymyr Grek on 27.07.2021.
//

import Alamofire


class NetworkRequestInterceptor: RequestInterceptor {
    let retryLimit = 5
    let retryDelay : TimeInterval = 3
    var isRefreshing: Bool = false
    
    func adapt(_ urlRequest: URLRequest, for session: Session, completion: @escaping (Swift.Result<URLRequest, Error>) -> Void) {
        var request = urlRequest
        if let token = KeyChainManager.shared.getToken() {
            request.setValue("Bearer " + token, forHTTPHeaderField: "Authorization")
        }
        completion(.success(request))
    }

    func retry(_ request: Request, for session: Session, dueTo error: Error,
               completion: @escaping (RetryResult) -> Void) {
        
        let response = request.task?.response as? HTTPURLResponse
        
        if response?.statusCode == 401, request.retryCount < retryLimit {
            print("\nretried; retry count: \(request.retryCount)\n")

            let credentials =  KeyChainManager.shared.getUserCredentials()
            if let apiKey = credentials.apiKey, let apiSecret = credentials.secretKey {
                APIManager.shared.authorize(apiKey: apiKey, apiSecret: apiSecret) { (success) in
                    success ? completion(.retry) : completion(.doNotRetry)
                }
            } else {
                return completion(.doNotRetry)
            }
        } else {
            return completion(.doNotRetry)
          }
        
    }
}
