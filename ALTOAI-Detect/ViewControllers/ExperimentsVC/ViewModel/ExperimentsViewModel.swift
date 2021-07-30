//
//  ExperimentsViewModel.swift
//  ALTOAI-Detect
//
//  Created by Volodymyr Grek on 29.07.2021.
//

import Foundation

class ExperimentsViewModel {
    var scene : Scene?
    var objects: [Experiment]?
    
    init(scene:Scene) {
        self.scene = scene
    }
  
    init() {
    }
    
    func getData(completion: ((Bool) -> Void)?) {
        guard let sceneId = scene?.id else {return}
        
        APIManager.shared.getExperiments(sceneId: sceneId) { (fetched) in
            self.objects = fetched
            completion?(self.objects?.count ?? 0 > 0)
        }
    }
}
