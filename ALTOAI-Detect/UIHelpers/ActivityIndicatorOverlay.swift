//
//  ActivityIndicatorOverlay.swift
//  ALTOAI-Detect
//
//  Created by Volodymyr Grek on 05.08.2021.
//

import UIKit

fileprivate let overlayViewTag: Int = 250189
fileprivate let activityIndicatorViewTag: Int = 250190

// Public interface
extension UIView {
    func displayAnimatedActivityIndicatorView() {
        setActivityIndicatorView()
    }

    func hideAnimatedActivityIndicatorView() {
        removeActivityIndicatorView()
    }
}

extension UIViewController {
    private var overlayContainerView: UIView {
        if let navigationView: UIView = navigationController?.view {
            return navigationView
        }
        return view
    }

    func displayAnimatedActivityIndicatorView() {
        overlayContainerView.displayAnimatedActivityIndicatorView()
    }

    func hideAnimatedActivityIndicatorView() {
        overlayContainerView.hideAnimatedActivityIndicatorView()
    }
}

// Private interface
extension UIView {
    private var activityIndicatorView: AltoActivityIndicatorView {
        let size : CGFloat = min(min(self.bounds.size.width, self.bounds.size.height), 18)
        let view: AltoActivityIndicatorView = AltoActivityIndicatorView(frame: CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: size, height: size)))
        
        view.translatesAutoresizingMaskIntoConstraints = false
        view.tag = activityIndicatorViewTag
        return view
    }

    private var overlayView: UIView {
        let size : CGFloat = min(min(self.bounds.size.width, self.bounds.size.height), 32)
        let view: UIView = UIView(frame: CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: size, height: size)))
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        view.alpha = 1.0
        view.tag = overlayViewTag
        return view
    }

    private func setActivityIndicatorView() {
        guard !isDisplayingActivityIndicatorOverlay() else { return }
        let overlayView: UIView = self.overlayView
        let activityIndicatorView: AltoActivityIndicatorView = self.activityIndicatorView

        //add subviews
        overlayView.addSubview(activityIndicatorView)
        
        addSubview(overlayView)

        //add overlay constraints
        //overlayView.heightAnchor.constraint(equalTo: heightAnchor).isActive = true
        //overlayView.widthAnchor.constraint(equalTo: widthAnchor).isActive = true
        
        overlayView.centerXAnchor.constraint(equalTo: centerXAnchor, constant: -9).isActive = true
        overlayView.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -9).isActive = true
        
        //add indicator constraints
        activityIndicatorView.centerXAnchor.constraint(equalTo: overlayView.centerXAnchor).isActive = true
        activityIndicatorView.centerYAnchor.constraint(equalTo: overlayView.centerYAnchor).isActive = true

        //animate indicator
        activityIndicatorView.startAnimating()
    }

    private func removeActivityIndicatorView() {
        guard let overlayView: UIView = getOverlayView(), let activityIndicator: AltoActivityIndicatorView = getActivityIndicatorView() else {
            return
        }
        UIView.animate(withDuration: 0.2, animations: {
            overlayView.alpha = 0.0
            activityIndicator.stopAnimating()
        }) { _ in
            activityIndicator.removeFromSuperview()
            overlayView.removeFromSuperview()
        }
    }

    private func isDisplayingActivityIndicatorOverlay() -> Bool {
        getActivityIndicatorView() != nil && getOverlayView() != nil
    }

    private func getActivityIndicatorView() -> AltoActivityIndicatorView? {
        viewWithTag(activityIndicatorViewTag) as? AltoActivityIndicatorView
    }

    private func getOverlayView() -> UIView? {
        viewWithTag(overlayViewTag)
    }
}
