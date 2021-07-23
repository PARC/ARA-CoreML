    //
//  LoginViewController.swift
//  ALTOAI-Detect
//
//  Created by Volodymyr Grek on 19.07.2021.
//

import UIKit

class LoginVC: UIViewController, UITextFieldDelegate {
    @IBOutlet weak var apiKeyTxtFld: UITextField!
    @IBOutlet weak var apiSecretTxtFld: UITextField!
    @IBOutlet weak var enterBtn: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
        let alert = UIAlertController(title: nil, message: "In implementation", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true)
    }
}
