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
    
    var isLoading = false
    
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
        
        self.navigationItem.title = viewModel.scene?.name
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
            return TableViewHeader.tblHeader("EXPERIMENTS", width: tableView.frame.width)
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
                self.tableView.setEmptyMessage(isLoading ? "" : "No available experiments")
            } else {
                self.tableView.restore()
            }
            
            return count
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
        tableView.deselectRow(at: indexPath, animated: false)
    }
    
    @IBSegueAction func makeExperimentRunVC(_ coder: NSCoder) -> ExperimentRunVC? {
        guard let selectedRow = tableView.indexPathForSelectedRow?.row, let experiment = viewModel.objects?[selectedRow] else {
            return nil
        }
        let viewModel = ExperimentRunViewModel(experiment: experiment)
        return ExperimentRunVC(viewModel: viewModel, coder: coder)
    }
}
