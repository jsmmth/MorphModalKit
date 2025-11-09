//
//  StickyElements.swift
//  FamilyValuesExample
//
//  Created by Joseph Smith on 26/07/2025.
//

import UIKit
import MorphModalKit

class StickyElements: StickyElementsContainer {
    private weak var current: ModalView?
    private let titleBar = TitleBar()
    private let primaryButton = PillButton(contentText: "Continue")
    private let secondaryButton = PillButton(contentText: "Cancel")
    private var primaryButtonConstraint: NSLayoutConstraint!
    private let buttonBackgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = .secondarySystemGroupedBackground
        return view
    }()

    required init(modalVC: ModalViewController) {
        super.init(modalVC: modalVC)
        
        /// Set defaults
        titleBar.onClose = { self.modalVC.hide() }
        titleBar.onBack = self.onBack
        secondaryButton.style = .secondary
        secondaryButton.isHidden = true
        
        setup()
        
        primaryButton.addTarget(self, action: #selector(onContinue), for: .touchUpInside)
        secondaryButton.addTarget(self, action: #selector(onCancel), for: .touchUpInside)
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    private func setup() {
        addSubview(titleBar)
        titleBar.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            titleBar.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 24),
            titleBar.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -24),
            titleBar.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            titleBar.heightAnchor.constraint(equalToConstant: 72)
        ])
        
        addSubview(buttonBackgroundView)
        buttonBackgroundView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            buttonBackgroundView.leadingAnchor.constraint(equalTo: leadingAnchor),
            buttonBackgroundView.trailingAnchor.constraint(equalTo: trailingAnchor),
            buttonBackgroundView.bottomAnchor.constraint(equalTo: bottomAnchor),
            buttonBackgroundView.heightAnchor.constraint(equalToConstant: 80)
        ])
        
        addSubview(secondaryButton)
        secondaryButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            secondaryButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 24),
            secondaryButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -24),
            secondaryButton.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.5, constant: -32)
        ])
        
        addSubview(primaryButton)
        primaryButton.translatesAutoresizingMaskIntoConstraints = false
        primaryButtonConstraint = primaryButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 24)
        NSLayoutConstraint.activate([
            primaryButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -24),
            primaryButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -24),
            primaryButtonConstraint,
        ])
    }
    
    override func contextDidChange(to newOwner: ModalView, from _: ModalView?, animated: Bool) {
        self.current = newOwner

        if current is ContentOne {
            titleBar.hasBackButton = false
            titleBar.titleText = "Content One"
            primaryButton.contentText = "Continue"
            self.hideSecondaryButton()
            return
        }
        
        if current is ContentTwo {
            titleBar.hasBackButton = true
            titleBar.titleText = "Content Two"
            primaryButton.contentText = "Continue"
            self.showSecondaryButton()
            return
        }
        
        if current is ContentThree {
            titleBar.hasBackButton = true
            titleBar.titleText = "Content Three"
            primaryButton.contentText = "Continue and Finish"
            self.hideSecondaryButton()
            return
        }
    }
    
    private func hideSecondaryButton() {
        guard !secondaryButton.isHidden else { return }
        primaryButtonConstraint.isActive = false
        primaryButtonConstraint = primaryButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 24)
        primaryButtonConstraint.isActive = true
        UIView.animate(
            withDuration: 0.25,
            delay: 0,
            options: [.allowUserInteraction, .beginFromCurrentState, .curveEaseOut],
            animations: {
                self.secondaryButton.alpha = 0
                self.secondaryButton.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
                self.layoutIfNeeded()
            }, completion: { _ in
                self.secondaryButton.isHidden = true
            })
    }
    
    private func showSecondaryButton() {
        guard secondaryButton.isHidden else { return }
        
        secondaryButton.alpha = 0
        secondaryButton.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        secondaryButton.isHidden = false
        primaryButtonConstraint.isActive = false
        primaryButtonConstraint = primaryButton.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.5, constant: -32)
        primaryButtonConstraint.isActive = true
        UIView.animate(
            withDuration: 0.25,
            delay: 0,
            options: [.allowUserInteraction, .beginFromCurrentState, .curveEaseOut],
            animations: {
                self.secondaryButton.alpha = 1
                self.secondaryButton.transform = .identity
                self.layoutIfNeeded()
            })
    }

    private func onBack() {
        if current is ContentTwo {
            modalVC.replace(with: ContentOne())
            return
        }
        
        if current is ContentThree {
            modalVC.replace(with: ContentTwo())
            return
        }
    }
    
    @objc private func onCancel() {
        modalVC.hide()
    }
    
    @objc private func onContinue() {
        if current is ContentOne {
            modalVC.replace(with: ContentTwo())
            return
        }
        
        if current is ContentTwo {
            modalVC.replace(with: ContentThree())
            return
        }
        
        if current is ContentThree {
            modalVC.hide()
            return
        }
    }
}
