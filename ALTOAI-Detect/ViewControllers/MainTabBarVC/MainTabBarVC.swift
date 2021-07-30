//
//  MainTabBarVC.swift
//  ALTOAI-Detect
//
//  Created by Volodymyr Grek on 30.07.2021.
//

import UIKit

class MainTabBarVC : UITabBarController, UITabBarControllerDelegate {
    override func viewDidLoad() {
        super.viewDidLoad()
        self.delegate = self
    }
    
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        return viewController != tabBarController.selectedViewController
    }
}
