//
//  ProjectsViewModel.swift
//  ALTOAI-Detect
//
//  Created by Volodymyr Grek on 29.07.2021.
//

import Foundation

class ProjectsViewModel {
    var projectId : String?
    var objects: [Project]?
    
    init(projectId:String) {
        self.projectId = projectId
    }
  
    init() {
    }
    
    func getData(completion: ((Bool) -> Void)?) {
        APIManager.shared.getProjects() { (fetched, error) in
            self.objects = fetched
            completion?(error == nil)
        }
    }
}
