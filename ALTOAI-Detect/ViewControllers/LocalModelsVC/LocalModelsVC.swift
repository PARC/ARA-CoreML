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

class LocalModelsVC: UIViewController, UITableViewDelegate, UITableViewDataSource, UIDocumentPickerDelegate, LocalModelTableViewCellDelegate {
   
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var browseButton: UIButton!
    @IBOutlet weak var addButton: UIButton!
    @IBOutlet weak var descriptionLabel: UILabel!
    
    lazy var viewModel: LocalViewModel = {
        return LocalViewModel()
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.tableFooterView = UIView(frame: .zero)
        tableView.layoutMargins = UIEdgeInsets.zero
        tableView.separatorInset = UIEdgeInsets.zero
        tableView.layoutMargins = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 0)
        
        loadData()
    }
    
    func loadData(animated: Bool = true) {
        displayAnimatedActivityIndicatorView()
        viewModel.getData()
        
        let hasData = viewModel.objects?.count ?? 0 > 0

        tableView.isHidden = !hasData
        browseButton.isHidden = hasData
        addButton.isHidden = !hasData
        descriptionLabel.isHidden = hasData
        
        self.tableView.reloadData()

        hideAnimatedActivityIndicatorView()
    }
    
    @IBAction func addPressed(_ sender: Any) {
        openDocumentsPicker()
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
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let count = viewModel.objects?.count ?? 0
        return count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "localModelCell", for: indexPath) as! LocalModelTableViewCell
        cell.delegate = self
        if let object = viewModel.objects?[indexPath.row] {
            cell.titleLabel?.text = object
            cell.runButton.isEnabled = true
        }
        return cell
    }
   
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if let object = viewModel.objects?[indexPath.row] {
            self.displayAnimatedActivityIndicatorView()
            viewModel.openModel(name: object) { (yolo, errorString) in
                self.hideAnimatedActivityIndicatorView()
                if let yolo = yolo {
                    let storyboard = UIStoryboard(name: "Main", bundle: nil)
                    
                    if let cameraVC = storyboard.instantiateViewController(withIdentifier: "CameraVCID") as? CameraVC {
                        cameraVC.yolo = yolo
                        cameraVC.modalPresentationStyle = .fullScreen
                        self.present(cameraVC, animated: true, completion: nil)
                    }
                } else {
                    let alert = UIAlertController(title: nil, message: errorString, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self.present(alert, animated: true)
                }
            }
        }
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if (editingStyle == .delete) {
            if let object = viewModel.objects?[indexPath.row] {
                let alert = UIAlertController(title: "Delete download?", message: "Downloaded model will be deleted, you may download it again anytime", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { _ in
                    self.viewModel.removeModel(name: object)
                    self.loadData()
                    self.tableView.reloadData()
                }))
                self.present(alert, animated: true)
            }
        }
    }
    
    func didTapLocalModelRunButtonInCell(cell: LocalModelTableViewCell) {
        if let indexPath = tableView.indexPath(for: cell){
            self.tableView(tableView, didSelectRowAt: indexPath)
        }
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        self.displayAnimatedActivityIndicatorView()
        ModelOperationsHelper.getModelFromArchive(urls.first!, isLocal: true) { yolo in
            self.hideAnimatedActivityIndicatorView()
            if let _ = yolo {
                self.loadData()
                self.tableView.reloadData()
            } else {
                let alert = UIAlertController(title: nil, message: "Your zip archive doesn't contain model and json file", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(alert, animated: true)
            }
            
        }
    }
}
