//
//  UIViewController+MorphModal.swift
//  
//
//  Created by Joseph Smith on 05/07/2025.
//

import UIKit

public extension UIViewController {
    /// Presents a root modal stack using `DialogViewController` as the host.
    ///
    /// - Parameters:
    ///   - root: The root `DialogView` to show.
    ///   - sticky: Optional sticky elements that remain visible while replacing content (morphing). Defaults to `nil`.
    ///   - animated: Whether to animate the presentation. Defaults to `true`.
    ///   - showsOverlay: Whether to show the dimmed background overlay. Defaults to `true`.
    ///   - dismissable: Whether the modal can be dismissed. Defaults to `true`.
    func presentModal(
        _ root: ModalView,
        options: ModalOptions = ModalOptions.default,
        sticky: StickyElementsContainer.Type? = nil,
        animated: Bool = true,
        showsOverlay: Bool = true) {
            let host = ModalViewController()
            host.modalPresentationStyle = .overFullScreen
            host.modalTransitionStyle   = .crossDissolve
            present(host, animated: false) {
                host.present(
                    root,
                    sticky: sticky,
                    animated: animated,
                    showsOverlay: showsOverlay)
            }
    }
}
