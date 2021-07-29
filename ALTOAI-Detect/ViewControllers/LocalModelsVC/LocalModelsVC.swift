//
//  LocalModelsViewController.swift
//  ALTOAI-Detect
//
//  Created by Volodymyr Grek on 19.07.2021.
//

import UIKit
import Vision
import ZIPFoundation
import AVFoundation

class LocalModelsVC: UIViewController, UITableViewDelegate, UITableViewDataSource, UIDocumentPickerDelegate {
   
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var browseButton: UIButton!
    @IBOutlet weak var addButton: UIButton!
    @IBOutlet weak var descriptionLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func addPressed(_ sender: Any) {
        
    }
    
    @IBAction func browsePressed(_ sender: Any) {
        openDocumentsPicker()
    }
    
    func openDocumentsPicker() {
        let documentPickerController = UIDocumentPickerViewController(
            forOpeningContentTypes: [UTType.zip], asCopy: true)
        documentPickerController.allowsMultipleSelection = false
        documentPickerController.delegate = self
        self.present(documentPickerController, animated: true)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "myCell", for: indexPath)// as! ourCell
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 0
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        view.activityStartAnimating()
        unzip(urls.first!)
    }
    
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        //startVideoCapture()
    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }
    
    func unzip(_ zipURL:URL) {
       // guard let zipURL = zipURL else { return }
        
        let fileManager = FileManager()
        var destinationURL = getDocumentsDirectory()
        
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
        compileModel(at: destinationURL)
        view.activityStopAnimating()
    }
    
    func compileModel(at url:URL) {
        let yolo : YOLO = YOLO()
        var modelLoaded = false
        var jsonLoaded = false
        
        let fileManager = FileManager.default
        let enumerator: FileManager.DirectoryEnumerator = fileManager.enumerator(atPath: url.path)!
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
        if (jsonLoaded && modelLoaded) {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            
            if let cameraVC = storyboard.instantiateViewController(withIdentifier: "CameraVCID") as? CameraVC {
                cameraVC.yolo = yolo
                cameraVC.modalPresentationStyle = .fullScreen
                present(cameraVC, animated: true, completion: nil)
            }
        } else {
            let alert = UIAlertController(title: nil, message: "Your zip archive doesn't contain model and json file", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true)
        }
    }
}
