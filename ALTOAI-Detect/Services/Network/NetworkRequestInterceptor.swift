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
            print("\nadapted; token added to the header field is: \(token)\n")
        }
        completion(.success(request))
    }

    func retry(_ request: Request, for session: Session, dueTo error: Error,
               completion: @escaping (RetryResult) -> Void) {
        if let afError = error.asAFError,
           afError.isRequestRetryError {
            // AF calls the retrier a second time with a RetryError
            // Prevent double calls by exiting
            //super.retry(request, for: session, dueTo: error, completion: completion)
            return
        }
        
        let response = request.task?.response as? HTTPURLResponse
        
        if response?.statusCode == 401, request.retryCount < retryLimit {
            print("\nretried; retry count: \(request.retryCount)\n")
            completion(.retryWithDelay(retryDelay))
//            fetchAccessToken { (success) in
//                success ? completion(.retryWithDelay(self.retryDelay)) : completion(.doNotRetry)
//            }
        } else {
            return completion(.doNotRetry)
          }
        
    }
}
