//
//  ScrollStickyElements.swift
//  UIKitExample
//
//  Created by Joseph Smith on 06/07/2025.
//

import UIKit
import MorphModalKit

// This is an example of using a different StickyElementsContainer for a push
// Realistically you'd probably have this gradient view within the ModalView for the ScrollModal
// This is just showcasing how you could have different sticky elements per stack push
class ScrollStickyElements: StickyElementsContainer {
    private let gradientContainer = UIView()

    required init(modalVC: ModalViewController) {
        super.init(modalVC: modalVC)
        
        gradientContainer.translatesAutoresizingMaskIntoConstraints = false
        gradientContainer.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        addSubview(gradientContainer)
        NSLayoutConstraint.activate([
            gradientContainer.topAnchor.constraint(equalTo: topAnchor),
            gradientContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            gradientContainer.trailingAnchor.constraint(equalTo: trailingAnchor),
            gradientContainer.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let gradient = CAGradientLayer()
        gradient.colors = [
            UIColor.secondarySystemGroupedBackground.cgColor,
            UIColor.secondarySystemGroupedBackground.withAlphaComponent(0).cgColor
        ]
        gradient.startPoint = CGPoint(x: 0.5, y: 0.0)
        gradient.endPoint = CGPoint(x: 0.5, y: 1.0)
        gradient.frame = gradientContainer.bounds
        gradientContainer.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
        gradientContainer.layer.insertSublayer(gradient, at: 0)
    }
    
    override func contextDidChange(to newOwner: ModalView, from _: ModalView?, animated: Bool) {
        // No need to do anything here
    }
}
