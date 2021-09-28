//
//  ModelExtractor.swift
//  ALTOAI-Detect
//
//  Created by Volodymyr Grek on 29.07.2021.
//

import Foundation
import Vision

class ModelOperationsHelper {
    
    class func getModelFromArchive(_ zipURL:URL, isLocal:Bool = false, completion: ((YOLO?) -> Void)? = nil) {
        //guard let zipURL = zipURL else { return }
        
        let fileManager = FileManager()
        var destinationURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        if (isLocal) {
            destinationURL = destinationURL.appendingPathComponent("LocalModels")
            
            do {
                try FileManager.default.createDirectory(atPath: destinationURL.path, withIntermediateDirectories: true, attributes: nil)
            } catch let error as NSError {
                NSLog("Unable to create directory \(error.debugDescription)")
            }
        }
        
        destinationURL.appendPathComponent(zipURL.deletingPathExtension().lastPathComponent)
        do {
            try fileManager.createDirectory(at: destinationURL, withIntermediateDirectories: true, attributes: nil)
            if (fileManager.fileExists(atPath: zipURL.path)) {
                try fileManager.unzipItem(at: zipURL, to: destinationURL)
                print("ZIP archive extracted to: \(destinationURL)")
            }
        } catch {
            print("Extraction of ZIP archive failed with error:\(error)")
        }
        checkDirectoryContainModelAndJSON(at: destinationURL) { yolo in
            completion?(yolo)
        }
    }
    
    class func checkDirectoryContainModelAndJSON(at url:URL) -> Bool {
        var modelExist = false
        var jsonExist = false
        
        let fileManager = FileManager.default
        guard let enumerator = fileManager.enumerator(atPath: url.path) else {
            return false
        }
        
        while let element = enumerator.nextObject() as? String {
            if (modelExist && jsonExist) {
                break
            }
            
            if (element.hasSuffix(".mlmodel")) {
                modelExist = true
                continue
            } else if (element.hasSuffix(".json")) {
                jsonExist = true
                continue
            }
        }
        
        return modelExist && jsonExist
    }
    
    class func checkDirectoryContainModelAndJSON(at url:URL, completion: ((YOLO?) -> Void)) {
        let yolo : YOLO = YOLO()
        var modelLoaded = false
        var jsonLoaded = false
        
        let fileManager = FileManager.default
        guard let enumerator = fileManager.enumerator(atPath: url.path) else {
            completion(nil)
            return
        }
        while let element = enumerator.nextObject() as? String {
            if (jsonLoaded && modelLoaded) {
                break
            }
            
            if (element.hasSuffix(".mlmodel")) {
                
                let modelURL = URL(fileURLWithPath: url.path+"/"+element)
                guard let compiledModelURL = try? MLModel.compileModel(at: modelURL)else {
                    print("Error in compiling model.")
                    return
                }
                guard let model = try? MLModel(contentsOf: compiledModelURL) else {
                    print("Error in getting model")
                    return
                }
                let yoloModel = yolo_model(model: model)
                yolo.model = yoloModel
                modelLoaded = true
                continue
            } else if (element.hasSuffix(".json")) {
                do {
                    let data = try Data(contentsOf: URL(fileURLWithPath: url.path+"/"+element), options: .mappedIfSafe)
                    let json = try JSONSerialization.jsonObject(with: data, options: .mutableLeaves)
                    print(json)
                    if let json = json as? Dictionary<String, AnyObject>, let model = json["model"] as? Dictionary<String, AnyObject> {
                        let input_shapes = model["input_shapes"] as? Dictionary ?? [:]
                        let height = input_shapes["height"] as? Int ?? 416
                        let width = input_shapes["width"] as? Int ?? 416
                        yolo.inputHeight = height
                        yolo.inputWidth = width
                        
                        let classes = model["classes"] as? Array<Dictionary<String, AnyObject>> ?? []
                        let names = classes.compactMap { $0["name"] } as! Array<String>
                        if (names.count>0) {
                            yolo.numClasses = names.count
                            yolo.labels = names
                            jsonLoaded = true
                        }
                    }
                } catch {
                    print("Error in getting json")
                }
                continue
            } else {
                continue
            }
        }
        
        completion(jsonLoaded && modelLoaded ? yolo : nil)
    }
}
