//
//  ExperimentRunVC.swift
//  ALTOAI-Detect
//
//  Created by Volodymyr Grek on 29.07.2021.
//

import Foundation
import UIKit

class ExperimentRunVC : UIViewController, UITableViewDelegate, UITableViewDataSource, ExperimentRunTableViewCellDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    let refreshControl = UIRefreshControl()
    
    var isLoading = false
    
    lazy var viewModel: ExperimentRunViewModel = {
        return ExperimentRunViewModel()
    }()
    
    init?(viewModel: ExperimentRunViewModel, coder: NSCoder) {
        super.init(coder: coder)
        self.viewModel = viewModel
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        loadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.tableFooterView = UIView(frame: .zero)
        tableView.layoutMargins = UIEdgeInsets.zero
        tableView.separatorInset = UIEdgeInsets.zero
        tableView.alwaysBounceVertical = true
        tableView.layoutMargins = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 0)
        
        refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
        refreshControl.addTarget(self, action: #selector(self.refresh(_:)), for: .valueChanged)
        tableView.addSubview(refreshControl)
        
        self.navigationItem.title = viewModel.experiment?.name ?? viewModel.experiment?.id
        loadData()
    }
    
    @objc func refresh(_ sender: AnyObject) {
        loadData()
    }
    
    func loadData(animated: Bool = true) {
        self.displayAnimatedActivityIndicatorView()
        isLoading = true
        viewModel.getData { _ in
            self.isLoading = false
            self.refreshControl.endRefreshing()
            self.hideAnimatedActivityIndicatorView()
            self.tableView.reloadData()
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let count = viewModel.objects?.count, count > 0 else {
            return nil
        }
        return TableViewHeader.tblHeader("EXPERIMENT RUNS", width: tableView.frame.width)
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard let count = viewModel.objects?.count, count > 0 else {
            return 0
        }
        return 40
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let count = viewModel.objects?.count ?? 0
        
        if count == 0 {
            self.tableView.setEmptyMessage(isLoading ? "" : "No available experiment runs")
        } else {
            self.tableView.restore()
        }
        
        return count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "experimentRunCell", for: indexPath) as! ExperimentRunTableViewCell
        cell.delegate = self
        if let object = viewModel.objects?[indexPath.row] {
            cell.titleLabel?.text = object.id
            if let experimentId = viewModel.experiment?.id {
                viewModel.checkIfModelDownloaded(experimentId: experimentId, runId: object.id) { yolo in
                    cell.runButton.isEnabled = yolo != nil
                    cell.statusImgView.image =  UIImage(named:yolo != nil ? "ready" : "download")
                }
            }
        }
        return cell
    }
   
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if let object = viewModel.objects?[indexPath.row] {
            self.tableView.displayAnimatedActivityIndicatorView()
            viewModel.downloadModelIfNeeded(experimentRunId: object.id) { (yolo, errorString) in
                self.tableView.hideAnimatedActivityIndicatorView()
                self.tableView.reloadRows(at: [indexPath], with: .automatic)
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
        if let objectId = viewModel.objects?[indexPath.row].id, let experimentId = viewModel.experiment?.id {
            return self.viewModel.checkIfModelDownloaded(experimentId: experimentId, runId: objectId)
        }
        return false
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if (editingStyle == .delete) {
            if let object = viewModel.objects?[indexPath.row] {
                let alert = UIAlertController(title: "Delete download?", message: "Downloaded model will be deleted, you may download it again anytime", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { _ in
                    self.viewModel.removeModel(runId: object.id)
                    self.tableView.reloadRows(at: [indexPath], with: .automatic)
                }))
                self.present(alert, animated: true)
            }
        }
    }
    
    func didTapExperimentRunButtonInCell(cell: ExperimentRunTableViewCell) {
        if let indexPath = tableView.indexPath(for: cell){
            self.tableView(tableView, didSelectRowAt: indexPath)
        }
    }
}
