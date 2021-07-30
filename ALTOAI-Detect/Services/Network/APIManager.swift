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
            guard let objects = response.value else {
              return
            }
            completion(objects)
          }
    }
    
    func getScenes(projectId : String, completion: @escaping ([Scene]) -> Void) {
        request?.cancel()
        request =
            sessionManager.request(APIRouter.getScenes(projectId: projectId)).responseDecodable(of: [Scene].self) { response in
            guard let objects = response.value else {
              return
            }
            completion(objects)
          }
    }
    
    func getExperiments(sceneId : String, completion: @escaping ([Experiment]) -> Void) {
        request?.cancel()
        request =
            sessionManager.request(APIRouter.getExperiments(sceneId: sceneId)).responseDecodable(of: [Experiment].self) { response in
            guard let objects = response.value else {
              return
            }
            completion(objects)
          }
    }
    
    func getExperimentRuns(experimentId : String, completion: @escaping ([ExperimentRun]) -> Void) {
        request?.cancel()
        request =
            sessionManager.request(APIRouter.getExperimentRun(experimentId: experimentId)).responseDecodable(of: [ExperimentRun].self) { response in
            guard let objects = response.value else {
              return
            }
            completion(objects)
          }
    }
    
    func downloadModel(experimentId : String, runId: String, completion: @escaping (URL?) -> Void) {
        request?.cancel()
        
        let destination: DownloadRequest.Destination = { _, _ in
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileURL = documentsURL.appendingPathComponent("\(experimentId)-\(runId).zip")
            
            return (fileURL, [.removePreviousFile, .createIntermediateDirectories])
        }
        
        request =
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

