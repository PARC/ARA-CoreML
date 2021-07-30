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
        
        APIManager.shared.getExperimentRuns(experimentId: experimentId) { (fetched) in
            self.objects = fetched
            completion?(self.objects?.count ?? 0 > 0)
        }
    }
    
    func downloadModelIfNeeded(experimentRunId: String, completion: @escaping ((YOLO?, String?) -> Void)) {
        guard let experimentId = experiment?.id else {return}
        
        checkIfModelDownloaded(experimentId: experimentId, runId: experimentRunId) { yolo in
            if let yolo = yolo {
                completion(yolo, nil)
            } else {
                APIManager.shared.downloadModel(experimentId: experimentId, runId: experimentRunId) { zipURL in
                    if let zipURL = zipURL {
                        ModelExtractor.getModelFromArchive(zipURL) { yolo in
                            if let yolo = yolo {
                                completion(yolo, nil)
                            } else {
                                completion(nil, "Your zip archive doesn't contain model and json file")
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
        
       // let zipURL = documentsURL.appendingPathComponent("\(experimentId)-\(runId).zip")
        let modelDirURL = documentsURL.appendingPathComponent("\(experimentId)-\(runId)")
       // let jsonURL = documentsURL.appendingPathComponent("\(experimentId)-\(runId)\\")
        ModelExtractor.checkDirectoryContainModelAndJSON(at: modelDirURL) { yolo in
             completion(yolo)
        }
    }
}
