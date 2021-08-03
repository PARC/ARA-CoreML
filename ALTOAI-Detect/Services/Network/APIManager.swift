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
    
    let sessionManager: Session = {
        let networkLogger = NetworkLogger()
        let interceptor = NetworkRequestInterceptor()
        let configuration = URLSessionConfiguration.af.default
        configuration.timeoutIntervalForRequest = 30
        configuration.waitsForConnectivity = true
    
        return Session(configuration: configuration, interceptor: interceptor, eventMonitors: [networkLogger])
    }()

    func authorize(apiKey:String, apiSecret: String, completion: @escaping (Bool, Error?) -> Void) {
        sessionManager.request(APIRouter.login(apiKey: apiKey, apiSecret: apiSecret)).responseDecodable(of: AccessToken.self) { response in
            if response.response?.statusCode == 400  {
                completion(false, CustomError.incorrectCredentials)
            } else {
                guard let token = response.value else {
                    return completion(false, response.error)
                }
                KeyChainManager.shared.signIn(apiKey: apiKey, secretKey: apiSecret, token: token.accessToken)
                completion(true, nil)
            }
        }
    }
    
    func getProjects(completion: @escaping ([Project]?, Error?) -> Void) {
        sessionManager.request(APIRouter.getProjects).responseDecodable(of: [Project].self) { response in
            guard let objects = response.value else {
                completion(nil, CustomError.cantGetProjects)
                return
            }
            completion(objects, nil)
        }
    }
    
    func getScenes(projectId : String, completion: @escaping ([Scene]?, Error?) -> Void) {
        sessionManager.request(APIRouter.getScenes(projectId: projectId)).responseDecodable(of: [Scene].self) { response in
            guard let objects = response.value else {
                completion(nil, CustomError.cantGetScenes)
                return
            }
            completion(objects, nil)
        }
    }
    
    func getExperiments(sceneId : String, completion: @escaping ([Experiment]?, Error?) -> Void) {
        sessionManager.request(APIRouter.getExperiments(sceneId: sceneId)).responseDecodable(of: [Experiment].self) { response in
            guard let objects = response.value else {
                completion(nil, CustomError.cantGetExperiments)
                return
            }
            completion(objects, nil)
        }
    }
    
    func getExperimentRuns(experimentId : String, completion: @escaping ([ExperimentRun]?, Error?) -> Void) {
        sessionManager.request(APIRouter.getExperimentRun(experimentId: experimentId)).responseDecodable(of: [ExperimentRun].self) { response in
            guard let objects = response.value else {
                completion(nil, CustomError.cantGetExperimentRuns)
                return
            }
            completion(objects, nil)
        }
    }
    
    func downloadModel(experimentId : String, runId: String, completion: @escaping (URL?) -> Void) {
        let destination: DownloadRequest.Destination = { _, _ in
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileURL = documentsURL.appendingPathComponent("\(experimentId)-\(runId).zip")
            
            return (fileURL, [.removePreviousFile, .createIntermediateDirectories])
        }
        
        sessionManager.download(APIRouter.getModel(experimentId: experimentId, runId: runId) , to:destination).response { response in
            if response.error == nil, let zipURL = response.fileURL {
                print(zipURL)
                completion(zipURL)
            } else {
                completion(nil)
            }
        }
    }
}

