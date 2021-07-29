//
//  APIRouter.swift
//  ALTOAI-Detect
//
//  Created by Volodymyr Grek on 20.07.2021.
//

import Foundation
import Alamofire
import SimpleKeychain

enum APIRouter: APIConfiguration {
    
    case login(apiKey:String, apiSecret:String)
    case getProjects
    case getScenes(projectId:String)
    case getExperiments(sceneId:String)
    case getExperimentRun(experimentId:String)
    case getExperimentRunModel(experimentId:String, runId:String)
    
    // MARK: - HTTPMethod
    var method: HTTPMethod {
        switch self {
        case .login:
            return .post
        case .getProjects:
            return .get
        case .getScenes:
            return .get
        case .getExperiments:
            return .get
        case .getExperimentRun:
            return .get
        case .getExperimentRunModel:
            return .get
        }
    }
    // MARK: - Parameters
     var parameters: RequestParams {
        switch self {
        case .login(let apiKey, let apiSecret):
            return .body(["client_id":apiKey,"client_secret":apiSecret])
        case .getProjects:
            return.body([:])
        case .getScenes:
            return.body([:])
        case .getExperiments:
            return.body([:])
        case .getExperimentRun:
            return.body([:])
        case .getExperimentRunModel:
            return.body([:])
        }
    }
    
    // MARK: - Path
    var path: String {
        switch self {
        case .login:
            return "/auth"
        case .getProjects:
            return "/ar/data/projects"
        case .getScenes(let projectId):
            return "/ar/data/projects/\(projectId)/scenes"
        case .getExperiments(let sceneId):
            return "/ar/data/scenes/\(sceneId)/experiments"
        case .getExperimentRun(let experimentId):
            return "/ar/data/experiments/\(experimentId)/run"
        case .getExperimentRunModel(let experimentId, let runId):
            return "/ar/data/experiments/\(experimentId)/run/\(runId)/models"
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
        if (method == .post) {
            urlRequest.setValue(ContentType.formEncode.rawValue, forHTTPHeaderField: HTTPHeaderField.contentType.rawValue)
        } else  if (method == .get) {
            urlRequest.setValue(ContentType.all.rawValue, forHTTPHeaderField: HTTPHeaderField.contentType.rawValue)
        }
        
        // Parameters
        switch parameters {
            
        case .body(let params):
            let jsonString = params.reduce("") { "\($0)\($1.0)=\($1.1)&" }.dropLast()
            if let data = jsonString.data(using: .utf8, allowLossyConversion: false), data.count > 0 {
                urlRequest.httpBody = data
            }

//            do {
//                urlRequest.httpBody = try JSONSerialization.data(withJSONObject: params, options: .prettyPrinted)
//            } catch let error {
//                print(error.localizedDescription)
//            }
//            break
            
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
