//
//  LocalViewModel.swift
//  ALTOAI-Detect
//
//  Created by Volodymyr Grek on 05.08.2021.
//

import Foundation

class LocalViewModel {
    var objects: [String]?
    
    func getData() {
        let localModelsDirURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("LocalModels")
        let fileManager = FileManager.default
        
        do {
            let directoryContents = try fileManager.contentsOfDirectory(at: localModelsDirURL, includingPropertiesForKeys: nil)
            objects = directoryContents.map{ $0.deletingPathExtension().lastPathComponent }
        } catch {
            print(error)
        }
    }
    
    func openModel(name: String, completion: @escaping ((YOLO?, String?) -> Void)) {
        let localModelsDirURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("LocalModels")
        
        let modelDirURL = localModelsDirURL.appendingPathComponent("\(name)")
        
        ModelOperationsHelper.checkDirectoryContainModelAndJSON(at: modelDirURL) { yolo in
            completion(yolo, nil)
        }
    }
    
    func removeModel(name: String) {
        let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let localModelsURL = documentsUrl.appendingPathComponent("LocalModels")
        
        let modelDirURL = localModelsURL.appendingPathComponent("\(name)")

        do {
            try FileManager.default.removeItem(at: modelDirURL)
        } catch {
            print(error)
        }
    }
}
