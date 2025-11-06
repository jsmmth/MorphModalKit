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
    ///   - dismissableFromOutsideTaps: Whether the modal can be dismissed from outside taps. Defaults to `true`.
    ///   - passThroughTouches: Whether the VC which is presenting can receieve touch events. Defaults to `false`.
    func presentModal(
        _ root: ModalView,
        options: ModalOptions = ModalOptions.default,
        sticky: StickyOption = .none,
        animated: Bool = true,
        showsOverlay: Bool = true,
        dismissableFromOutsideTaps: Bool = true,
        passThroughTouches: Bool = false) {
            let host = ModalViewController()
            host.modalPresentationStyle = .overFullScreen
            host.modalTransitionStyle   = .crossDissolve
            present(host, animated: false) {
                host.present(
                    root,
                    options: options,
                    sticky: sticky,
                    animated: animated,
                    showsOverlay: showsOverlay,
                    dismissableFromOutsideTaps: dismissableFromOutsideTaps,
                    passThroughTouches: passThroughTouches)
            }
    }
}
