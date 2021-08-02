//
//  ScenesViewModel.swift
//  ALTOAI-Detect
//
//  Created by Volodymyr Grek on 29.07.2021.
//

import Foundation

class ScenesViewModel {
    var project : Project?
    var objects: [Scene]?
    
    init(project:Project) {
        self.project = project
    }
  
    init() {
    }
    
    func getData(completion: ((Bool) -> Void)?) {
        guard let projectId = project?.id else {return}
        
        APIManager.shared.getScenes(projectId: projectId) { (fetched, error) in
            self.objects = fetched
            completion?(error == nil)
        }
    }
}
