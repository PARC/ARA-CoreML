//
//  ExperimentsVC.swift
//  ALTOAI-Detect
//
//  Created by Volodymyr Grek on 29.07.2021.
//

import Foundation
import UIKit

class ExperimentsVC : UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    
    let refreshControl = UIRefreshControl()
    
    lazy var viewModel: ExperimentsViewModel = {
        return ExperimentsViewModel()
    }()
    
    init?(viewModel: ExperimentsViewModel, coder: NSCoder) {
        super.init(coder: coder)
        self.viewModel = viewModel
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
        refreshControl.addTarget(self, action: #selector(self.refresh(_:)), for: .valueChanged)
        tableView.addSubview(refreshControl)
        
        self.navigationItem.title = viewModel.scene?.name
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
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "EXPERIMENTS"
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.objects?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "experimentCell", for: indexPath) //as! UITableViewCell
        if let object = viewModel.objects?[indexPath.row] {
            cell.textLabel?.text = object.name ?? object.id
        }
        return cell
    }
   
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.performSegue(withIdentifier: "toExperimentRuns", sender: self)
    }
    
    @IBSegueAction func makeExperimentRunVC(_ coder: NSCoder) -> ExperimentRunVC? {
        guard let selectedRow = tableView.indexPathForSelectedRow?.row, let experiment = viewModel.objects?[selectedRow] else {
            return nil
        }
        let viewModel = ExperimentRunViewModel(experiment: experiment)
        return ExperimentRunVC(viewModel: viewModel, coder: coder)
    }
}
