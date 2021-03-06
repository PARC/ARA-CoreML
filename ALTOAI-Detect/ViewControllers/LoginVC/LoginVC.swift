    //
    //  LoginViewController.swift
    //  ALTOAI-Detect
    //
    //  Created by Volodymyr Grek on 19.07.2021.
    //
    
    import UIKit
    import Alamofire
    import SimpleKeychain
    import Foundation
    
    class LoginVC: UIViewController, UITextFieldDelegate {
        @IBOutlet weak var apiKeyTxtFld: UITextField!
        @IBOutlet weak var apiSecretTxtFld: UITextField!
        @IBOutlet weak var enterBtn: UIButton!
        
        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            if let _ = KeyChainManager.shared.getToken() {
                performSegue(withIdentifier: "toProjects", sender: self)
            }
        }

        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            navigationController?.setNavigationBarHidden(true, animated: animated)
        }

        override func viewWillDisappear(_ animated: Bool) {
            super.viewWillDisappear(animated)
            navigationController?.setNavigationBarHidden(false, animated: animated)
        }
        
        override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
            if UIDevice.current.userInterfaceIdiom == .phone {
                return .portrait
            } else {
                return .all
            }
        }

        override func viewDidLoad() {
            super.viewDidLoad()
            
//                apiKeyTxtFld.text = "a6cec2e6-bdae-431f-b664-355c2ca31f27"
//                apiSecretTxtFld.text = "ee2f5923-f086-4cdb-9593-17cfac9b5bb4"
            
            enterBtn.setTitleColor(UIColor.white, for:.normal)
            enterBtn.setTitleColor(UIColor.init(red: 60/256.0, green: 60/256.0, blue: 67/256.0, alpha: 0.3), for:.disabled)
            
            setButtonState(apiKeyTxtFld.hasText && apiSecretTxtFld.hasText)
            
            let tapGesture = UITapGestureRecognizer(target: view, action: #selector(UIView.endEditing))
            tapGesture.cancelsTouchesInView = false
            view.addGestureRecognizer(tapGesture)
            
        }
        
        func setButtonState(_ enabled: Bool ) {
            enterBtn.isEnabled = enabled
            enterBtn.backgroundColor = enabled ? UIColor.init(red: 0.202, green: 0.425, blue: 0.781, alpha: 1) : UIColor.init(red: 116/256.0, green: 116/256.0, blue: 128/256.0, alpha: 0.08)
        }
        
        func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
            
            let otherTxtField = textField == apiKeyTxtFld ? apiSecretTxtFld : apiKeyTxtFld
            var updatedText : String? = nil
            if let text = textField.text,
               let textRange = Range(range, in: text) {
                updatedText = text.replacingCharacters(in: textRange,
                                                       with: string)
            }
            setButtonState((otherTxtField?.text?.count ?? 0 > 0) && (updatedText?.count ?? 0 > 0))
            
            return true
        }
        
        //Mark IBACTIONS
        @IBAction func login(_ sender: Any) {
            guard let apiKey = apiKeyTxtFld.text, let apiSecret = apiSecretTxtFld.text else { return }
            self.displayAnimatedActivityIndicatorView()
            APIManager.shared.authorize(apiKey: apiKey, apiSecret: apiSecret) { (isSuccess, error) in
                self.hideAnimatedActivityIndicatorView()
                
                if (isSuccess) {
                    self.performSegue(withIdentifier: "toProjects", sender: self)
                } else {
                    var message = "Something is wrong. Please try again"
                    if let error = error as? CustomError {
                        message = error.rawValue
                    }
                    
                    let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self.present(alert, animated: true)
                }
            }
        }
    }
