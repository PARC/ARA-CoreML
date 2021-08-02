//
//  ExperimentRunVC.swift
//  ALTOAI-Detect
//
//  Created by Volodymyr Grek on 29.07.2021.
//

import Foundation
import UIKit

class ExperimentRunVC : UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    
    let refreshControl = UIRefreshControl()
    
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.tableFooterView = UIView(frame: .zero)
        tableView.layoutMargins = UIEdgeInsets.zero
        tableView.separatorInset = UIEdgeInsets.zero
        tableView.alwaysBounceVertical = true
        
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
        tableView.activityStartAnimating()
        viewModel.getData { _ in
            self.refreshControl.endRefreshing()
            self.tableView.activityStopAnimating()
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
                self.tableView.setEmptyMessage("No available experiment runs")
            } else {
                self.tableView.restore()
            }
            
            return count
        }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "experimentRunCell", for: indexPath) //as! UITableViewCell
        if let object = viewModel.objects?[indexPath.row] {
            cell.textLabel?.text = object.id
        }
        return cell
    }
   
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let object = viewModel.objects?[indexPath.row] {
            viewModel.downloadModelIfNeeded(experimentRunId: object.id) { (yolo, errorString) in
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
}
