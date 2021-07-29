//
//  WorkspaceVC.swift
//  ALTOAI-Detect
//
//  Created by Volodymyr Grek on 28.07.2021.
//

import UIKit

class WorkspaceVC : UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var logoutButton: UIButton!
    
    let refreshControl = UIRefreshControl()
    
    var projects = [Project]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
        refreshControl.addTarget(self, action: #selector(self.refresh(_:)), for: .valueChanged)
        tableView.addSubview(refreshControl)
        
        loadData()
    }
    
    @objc func refresh(_ sender: AnyObject) {
        loadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    
    func loadData(animated: Bool = true) {
        tableView.activityStartAnimating()
        APIManager.shared.getProjects() { (fetched) in
            self.refreshControl.endRefreshing()
            self.tableView.activityStopAnimating()
            self.projects = fetched
            
            self.tableView.reloadData()
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return projects.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "projectCell", for: indexPath) //as! UITableViewCell
        cell.textLabel?.text = projects[indexPath.row].name
        return cell
    }
   
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print (projects[indexPath.row].id)
    }
    
    @IBAction func logout(_ sender: Any) {
        let refreshAlert = UIAlertController(title: nil, message: "Are you sure want to logout?", preferredStyle: .alert)

        refreshAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action: UIAlertAction!) in
            KeyChainManager.shared.signOutUser()
            self.navigationController?.popToRootViewController(animated: true)
        }))

        refreshAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
        }))

        present(refreshAlert, animated: true, completion: nil)
        
    }
    
}
