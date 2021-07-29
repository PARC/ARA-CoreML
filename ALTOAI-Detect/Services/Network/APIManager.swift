//
//  NetworkManager.swift
//  ALTOAI-Detect
//
//  Created by Volodymyr Grek on 27.07.2021.
//

import Alamofire

class APIManager {
    static let shared: APIManager = {
        return APIManager()
    }()
    
    typealias completionHandler = ((Result<Data, CustomError>) -> Void)
    
    var request: Alamofire.Request?
    
    let sessionManager: Session = {
        let networkLogger = NetworkLogger()
        let interceptor = NetworkRequestInterceptor()
        let configuration = URLSessionConfiguration.af.default
        configuration.timeoutIntervalForRequest = 30
        configuration.waitsForConnectivity = true
    
        return Session(configuration: configuration, interceptor: interceptor, eventMonitors: [networkLogger])
    }()

    func authorize(apiKey:String, apiSecret: String, completion: @escaping (Bool) -> Void) {
        request?.cancel()
        request =
        sessionManager.request(APIRouter.login(apiKey: apiKey, apiSecret: apiSecret)).responseDecodable(of: AccessToken.self) { response in
            guard let token = response.value else {
              return completion(false)
            }
            KeyChainManager.shared.signIn(apiKey: apiKey, secretKey: apiSecret, token: token.accessToken)
            completion(true)
        }
    }
    
    func getProjects(completion: @escaping ([Project]) -> Void) {
        request?.cancel()
        request =
            sessionManager.request(APIRouter.getProjects).responseDecodable(of: [Project].self) { response in
            guard let projects = response.value else {
              return
            }
            completion(projects)
          }
    }
}

