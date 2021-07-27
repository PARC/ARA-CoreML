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
        case .login(let client_id, let password):
            return .body(["client_id":client_id,"password":password])
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
