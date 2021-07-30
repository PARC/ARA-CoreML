//
//  ScenesVC.swift
//  ALTOAI-Detect
//
//  Created by Volodymyr Grek on 29.07.2021.
//

import UIKit

class ScenesVC : UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    
    let refreshControl = UIRefreshControl()
    
    lazy var viewModel: ScenesViewModel = {
        return ScenesViewModel()
    }()
    
    init?(viewModel: ScenesViewModel, coder: NSCoder) {
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
        
        self.navigationItem.title = viewModel.project?.name
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
        return "SCENES"
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.objects?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "sceneCell", for: indexPath) //as! UITableViewCell
        if let object = viewModel.objects?[indexPath.row] {
            cell.textLabel?.text = object.name ?? object.id
        }
        return cell
    }
   
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.performSegue(withIdentifier: "toExperiments", sender: self)
    }
    
    @IBSegueAction func makeExperimentsVC(_ coder: NSCoder) -> ExperimentsVC? {
        guard let selectedRow = tableView.indexPathForSelectedRow?.row, let scene = viewModel.objects?[selectedRow] else {
            return nil
        }
        let viewModel = ExperimentsViewModel(scene: scene)
        return ExperimentsVC(viewModel: viewModel, coder: coder)
    }
}
