//
//  LocalModelTableViewCell.swift
//  ALTOAI-Detect
//
//  Created by Volodymyr Grek on 05.08.2021.
//
import UIKit

@objc protocol LocalModelTableViewCellDelegate {
    @objc optional func didTapLocalModelRunButtonInCell(cell: LocalModelTableViewCell)
}

class LocalModelTableViewCell : UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var runButton: UIButton!
    
    weak var delegate: LocalModelTableViewCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        runButton.setImage(UIImage(named:"play"), for: .normal)
        runButton.setImage(UIImage(named:"play_disabled"), for: .disabled)
    }

    
    @IBAction func tapRun(_ sender: Any) {
        delegate?.didTapLocalModelRunButtonInCell?(cell: self)
    }
}
