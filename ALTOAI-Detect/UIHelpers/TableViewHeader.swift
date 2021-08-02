//
//  TableViewHeader.swift
//  ALTOAI-Detect
//
//  Created by Volodymyr Grek on 02.08.2021.
//

import UIKit

class TableViewHeader {
    
    class func tblHeader(_ title:String, width:CGFloat) -> UIView {
        
        let headerView = UIView.init(frame: CGRect.init(x: 0, y: 0, width: width, height: 40))
        
        let label = UILabel()
        let leftInset : CGFloat = 20.0
        
        label.frame = CGRect.init(x: leftInset, y: 0, width: headerView.frame.width-leftInset, height: headerView.frame.height-10)
        label.text = title
        label.font = .systemFont(ofSize:13)
        label.textColor = AppStyle.tableViewHeaderTitle
        
        headerView.addSubview(label)
        
        return headerView
    }
}
