//
//  ExperimentRunTableViewCell.swift
//  ALTOAI-Detect
//
//  Created by Volodymyr Grek on 05.08.2021.
//

import UIKit

@objc protocol ExperimentRunTableViewCellDelegate {
    @objc optional func didTapExperimentRunButtonInCell(cell: ExperimentRunTableViewCell)
}

class ExperimentRunTableViewCell : UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var statusImgView: UIImageView!
    @IBOutlet weak var runButton: UIButton!
    
    weak var delegate: ExperimentRunTableViewCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        runButton.setImage(UIImage(named:"play"), for: .normal)
        runButton.setImage(UIImage(named:"play_disabled"), for: .disabled)
    }
    
    func startLoading() {
        statusImgView.image = nil
        statusImgView.displayAnimatedActivityIndicatorView()
    }
    
    func stopLoading() {
        statusImgView.image = UIImage(named:"ready")
        statusImgView.hideAnimatedActivityIndicatorView()
    }
    
    @IBAction func tapRun(_ sender: Any) {
        delegate?.didTapExperimentRunButtonInCell?(cell: self)
    }
}
