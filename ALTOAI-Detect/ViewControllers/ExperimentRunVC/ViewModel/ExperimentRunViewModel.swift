//
//  ExperimentRunViewModel.swift
//  ALTOAI-Detect
//
//  Created by Volodymyr Grek on 29.07.2021.
//

import Foundation

class ExperimentRunViewModel {
    var experiment : Experiment?
    var objects: [ExperimentRun]?
    
    init(experiment:Experiment) {
        self.experiment = experiment
    }
  
    init() {
    }
    
    func getData(completion: ((Bool) -> Void)?) {
        guard let experimentId = experiment?.id else {return}
        
        APIManager.shared.getExperimentRuns(experimentId: experimentId) { (fetched, error) in
            
            self.objects = fetched?.filter({ run in
                return run.status == "COMPLETED"
            })
            completion?(error == nil)
        }
    }
    
    func removeModel(runId: String) {
        guard let experimentId = experiment?.id else {return}
        
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        
        let zipURL = documentsURL.appendingPathComponent("\(experimentId)-\(runId).zip")
        let modelDirURL = documentsURL.appendingPathComponent("\(experimentId)-\(runId)")
        
        let fileManager = FileManager.default
        
        try? fileManager.removeItem(at: zipURL)
        try? fileManager.removeItem(at: modelDirURL)
    }
    
    func downloadModelIfNeeded(experimentRunId: String, completion: @escaping ((YOLO?, String?) -> Void)) {
        guard let experimentId = experiment?.id else {return}
        
        checkIfModelDownloaded(experimentId: experimentId, runId: experimentRunId) { yolo in
            if let yolo = yolo {
                completion(yolo, nil)
            } else {
                APIManager.shared.downloadModel(experimentId: experimentId, runId: experimentRunId) { zipURL in
                    if let zipURL = zipURL {
                        ModelOperationsHelper.getModelFromArchive(zipURL) { yolo in
                            if let yolo = yolo {
                                completion(yolo, nil)
                            } else {
                                completion(nil, "Your zip archive is broken or doesn't contain model and json files")
                            }
                        }
                    } else {
                        completion(nil, "Something happen while downloading model archive")
                    }
                }
            }
        }
    }
    
    func checkIfModelDownloaded(experimentId: String, runId: String, completion: @escaping ((YOLO?) -> Void)) {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let modelDirURL = documentsURL.appendingPathComponent("\(experimentId)-\(runId)")
        // let zipURL = documentsURL.appendingPathComponent("\(experimentId)-\(runId).zip")
        // let jsonURL = documentsURL.appendingPathComponent("\(experimentId)-\(runId)\\")
        ModelOperationsHelper.checkDirectoryContainModelAndJSON(at: modelDirURL) { yolo in
            completion(yolo)
        }
    }
    
    func checkIfModelDownloaded(experimentId: String, runId: String) -> Bool  {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        //let modelDirURL = documentsURL.appendingPathComponent("\(experimentId)-\(runId)")
        let zipURL = documentsURL.appendingPathComponent("\(experimentId)-\(runId).zip")
        
        let zipExists = FileManager.default.fileExists(atPath: zipURL.path)
        
        return zipExists //ModelOperationsHelper.checkDirectoryContainModelAndJSON(at: modelDirURL)
    }
}
