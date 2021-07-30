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
        ModelExtractor.getModelFromArchive(urls.first!) { yolo in
            if let yolo = yolo {
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                
                if let cameraVC = storyboard.instantiateViewController(withIdentifier: "CameraVCID") as? CameraVC {
                    cameraVC.yolo = yolo
                    cameraVC.modalPresentationStyle = .fullScreen
                    self.present(cameraVC, animated: true, completion: nil)
                }
            } else {
                let alert = UIAlertController(title: nil, message: "Your zip archive doesn't contain model and json file", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(alert, animated: true)
            }
        }
    }
}
