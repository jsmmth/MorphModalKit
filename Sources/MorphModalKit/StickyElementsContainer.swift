//
//  StickyElementsContainer.swift
//  
//
//  Created by Joseph Smith on 05/07/2025.
//
import UIKit

/// Lives inside the `wrapper`, survives every morph, and is meant to be
/// subclassed by feature code to add header / footer etc
open class StickyElementsContainer: UIView {
    public weak var wrapper: UIView?
    public let safeArea = UILayoutGuide()
    public let modalVC: ModalViewController
    
    public required init(modalVC: ModalViewController) {
        self.modalVC = modalVC
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        addLayoutGuide(safeArea)
        NSLayoutConstraint.activate([
            safeArea.topAnchor.constraint(equalTo: topAnchor),
            safeArea.leadingAnchor.constraint(equalTo: leadingAnchor),
            safeArea.trailingAnchor.constraint(equalTo: trailingAnchor),
            safeArea.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let hit = super.hitTest(point, with: event)
        return (hit === self) ? nil : hit
    }
    
    /// Called whenever the front-most page changes.
    /// - Parameters:
    ///   - newOwner: the `ModalView` that just became front-most
    ///   - oldOwner: the one that just went to background (or `nil`)
    ///   - animated: matches the card-stack animation flag
    open func contextDidChange(to newOwner: ModalView,
                               from oldOwner: ModalView?,
                               animated: Bool) { /* default: no-op */ }
}
