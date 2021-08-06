//
//  AltoAcvtivityIndicatorView.swift
//  ALTOAI-Detect
//
//  Created by Volodymyr Grek on 06.08.2021.
//

import UIKit

/**
**GLSSpinActivityIndicatorView**
A view that displays a customizable spinning arc activity indicator.
*/

class AltoActivityIndicatorView: UIView {
    fileprivate var _color : UIColor? = UIColor(red: 101/255.0, green: 196/255.0, blue: 103/255.0, alpha: 1.0)
    fileprivate var _circleColor : UIColor? = UIColor(red: 208/255.0, green: 209/255.0, blue: 213/255.0, alpha: 1.0)
    fileprivate var progressLayer : CAShapeLayer?
    fileprivate var progressPath : CAShapeLayer?
    fileprivate var animating : Bool = false
    fileprivate var animation : CABasicAnimation?
    fileprivate var hideSpinnerPath : Bool = false
    
    /**
    If true, the activity indicator becomes hidden when stopped.
     */
    var hidesWhenStopped : Bool = false
    
    /**
    The color to be used for the indicator.
    */
    var color : UIColor? {
        get
        {
            return _color!
        }
        set
        {
            _color = newValue
            if let unwrappedColor = _color {
                self.progressLayer?.strokeColor = unwrappedColor.cgColor
                //self.progressPath?.strokeColor = unwrappedColor.withAlphaComponent(0.2).cgColor
            }
        }
    }
    
    var circleColor : UIColor? {
        get
        {
            return _circleColor!
        }
        set
        {
            _circleColor = newValue
            if let unwrappedColor = _circleColor {
                self.progressPath?.strokeColor = unwrappedColor.cgColor
            }
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    override required init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    /**
    Common initializer logic for the spin indicator.
    */
    fileprivate func commonInit() {
        self.backgroundColor = UIColor.clear
        let arcCenter = CGPoint(x: self.bounds.midX, y: self.bounds.midY)
        let radius = min(self.bounds.maxX, self.bounds.maxY)/2
        let circlePath = UIBezierPath(arcCenter: arcCenter, radius: radius, startAngle: CGFloat(0), endAngle: CGFloat(2*Double.pi), clockwise: true)
        self.progressLayer = CAShapeLayer()
        self.progressLayer?.frame = self.layer.bounds
        self.progressLayer?.path = circlePath.cgPath
        self.progressLayer?.fillColor = UIColor.clear.cgColor
        self.progressLayer?.lineWidth = 6.0
        self.progressLayer?.strokeStart = 0.0
        self.progressLayer?.strokeEnd = 0.3
        
        // background path
        self.progressPath = CAShapeLayer()
        self.progressPath?.path = circlePath.cgPath
        self.progressPath?.frame = self.layer.bounds
        self.progressPath?.fillColor = UIColor.clear.cgColor
        self.progressPath?.lineWidth = 6.0
        
        // color
        if let unwrappedColor = _color {
            self.progressLayer?.strokeColor = unwrappedColor.cgColor
            //self.progressPath?.strokeColor = unwrappedColor.withAlphaComponent(0.2).cgColor
        }
        if let unwrappedColor = _circleColor {
            self.progressPath?.strokeColor = unwrappedColor.cgColor
        }
        
        self.layer.addSublayer(self.progressPath!)
        self.layer.addSublayer(self.progressLayer!)
    }
    
    /**
    Sets the size of the arc, in terms of a fraction of a circle.
    
    *arcSize* - A CGFloat from 0.0 to 1.0.
    */
    func setSpinningArcSize(_ arcSize:CGFloat) {
        self.progressLayer?.strokeEnd = arcSize
    }
    
    /**
    Sets the visibility of the background circle path of the indicator.
    
    *showPath* - A boolean that indicates the path's visibility.
    */
    func showArcPath(_ showPath:Bool) {
        self.hideSpinnerPath = !showPath
        self.progressPath?.isHidden = !showPath
    }
    
    /**
    Sets the progress indicator line width.
    
    *arcWidth* - A CGFloat to use as width for drawing the indicator.
    */
    func setArcWidth(_ arcWidth:CGFloat) {
        self.progressLayer?.lineWidth = arcWidth
        self.progressPath?.lineWidth = arcWidth
    }
    
    /**
    Starts the spin animation.
    */
    func startAnimating() {
        if self.isAnimating()
        {
            return
        }
        self.progressLayer?.isHidden = false
        if (!self.hideSpinnerPath)
        {
            self.progressPath?.isHidden = false
        }
        self.animating = true
        self.animation = CABasicAnimation(keyPath:"transform.rotation.z")
        self.animation?.duration = 1.2
        self.animation?.isRemovedOnCompletion = false
        self.animation?.fromValue = 0.0
        self.animation?.toValue = 2*Double.pi
        self.animation?.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.linear)
        self.animation?.repeatCount = Float.infinity
        self.progressLayer?.add(self.animation!, forKey: "progressAnimation")

    }
    
    /**
    Stops the spin animation.
    */
    func stopAnimating() {
        if !self.isAnimating()
        {
            return
        }
        self.animating = false
        self.progressLayer?.isHidden = self.hidesWhenStopped
        if (!self.hideSpinnerPath)
        {
            self.progressPath?.isHidden = self.hidesWhenStopped
        }
        self.progressLayer?.removeAnimation(forKey: "progressAnimation")
    }
    
    /**
    Returns if the spin indicator is animating.
    
    *returns* - A boolean indicator if the animation is in progress.
    */
    func isAnimating() -> Bool {
        return self.animating
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if (self.layer.bounds != CGRect(x: 0, y: 0, width: 0, height: 0)) {
            self.progressLayer?.frame = self.layer.bounds
            self.progressPath?.frame = self.layer.bounds
        }
    }
}
