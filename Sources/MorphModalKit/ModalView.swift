//
//  ModalView.swift
//  MorphModalKit
//
//  Created by Joseph Smith on 05/07/2025.
//

import UIKit

public protocol ModalView: UIViewController {
    // Sizing
    func preferredHeight(for width: CGFloat) -> CGFloat

    // Dismissal policy
    var canDismiss: Bool { get }
    
    /// If you return a scroll-view here MorphModalKit will wire it up
    /// so a downward drag at its *top* dismisses the current sheet.
    var dismissalHandlingScrollView: UIScrollView? { get }

    // Lifecycle hooks
    func modalWillAppear()
    func modalDidAppear()
    func modalWillDisappear()
    func modalDidDisappear()
}

public extension ModalView {
    // Defaults
    func preferredHeight(for width: CGFloat) -> CGFloat { 0 }
    var canDismiss: Bool { true }
    var dismissalHandlingScrollView: UIScrollView? { nil }
    
    func modalWillAppear()    {}
    func modalDidAppear()     {}
    func modalWillDisappear() {}
    func modalDidDisappear()  {}
    
    // Access to modalVC
    var modalVC: ModalViewController? {
        if let parent = self.parent as? ModalViewController {
            return parent
        }
        return self.presentingViewController as? ModalViewController
    }
}
