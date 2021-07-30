//
//  WorkspaceVC.swift
//  ALTOAI-Detect
//
//  Created by Volodymyr Grek on 28.07.2021.
//

import UIKit

class ProjectsVC : UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var logoutButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    
    let refreshControl = UIRefreshControl()
    
    lazy var viewModel: ProjectsViewModel = {
        return ProjectsViewModel()
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
        refreshControl.addTarget(self, action: #selector(self.refresh(_:)), for: .valueChanged)
        tableView.addSubview(refreshControl)
    }
    
    @objc func refresh(_ sender: AnyObject) {
        loadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        
        loadData()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
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
        return "PROJECTS"
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.objects?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "projectCell", for: indexPath) //as! UITableViewCell
        cell.textLabel?.text = viewModel.objects?[indexPath.row].name ?? viewModel.objects?[indexPath.row].id
        return cell
    }
   
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.performSegue(withIdentifier: "toScenes", sender: self)
    }
    
    @IBSegueAction func makeScenesVC(_ coder: NSCoder) -> ScenesVC? {
        guard let selectedRow = tableView.indexPathForSelectedRow?.row, let project = viewModel.objects?[selectedRow] else {
            return nil
        }
        let viewModel = ScenesViewModel(project: project)
        return ScenesVC(viewModel: viewModel, coder: coder)
    }
    
    @IBAction func logout(_ sender: Any) {
        let logoutAlert = UIAlertController(title: nil, message: "Are you sure want to logout?", preferredStyle: .alert)

        logoutAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action: UIAlertAction!) in
            KeyChainManager.shared.signOutUser()
            self.navigationController?.popToRootViewController(animated: true)
        }))

        logoutAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
        }))

        present(logoutAlert, animated: true, completion: nil)
        
    }
    
}
