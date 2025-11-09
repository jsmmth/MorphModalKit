//
//  TitleBar.swift
//  FamilyValuesExample
//
//  Created by Joseph Smith on 26/07/2025.
//

import UIKit

/// Example title bar
/// This is used as an example to show how you can get similar effect to the dynamic tray approach Benji recently shared
/// This is not a production ready snippet and will likely need to be a bit stronger to hold up in production environments
/// But feel free to take this and alter this

class TitleBar: UIView {
    public var titleText: String? {
        didSet {
            titleDidUpdate()
        }
    }
    public var hasBackButton: Bool? {
        didSet {
            backButtonVisibilityDidChange()
        }
    }
    public var onBack: (() -> Void)?
    public var onClose: (() -> Void)?
    
    private var titleLeadingConstraint: NSLayoutConstraint!
    private let backButton = IconButton(icon: "chevron.left")
    private let closeButton = IconButton(icon: "xmark")
    private let seperatorLine = UIView()
    private let titleLabel: AnimatedUILabel = {
        let lbl = AnimatedUILabel()
        lbl.font = .systemFont(ofSize: 19, weight: .semibold)
        lbl.textColor = .label
        return lbl
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
        
        closeButton.addTarget(self, action: #selector(onClosePress), for: .touchUpInside)
        backButton.addTarget(self, action: #selector(onBackPress), for: .touchUpInside)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        // Title
        addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLeadingConstraint = titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor)
        
        NSLayoutConstraint.activate([
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
        
        // Back Button
        addSubview(backButton)
        backButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            backButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            backButton.leadingAnchor.constraint(equalTo: leadingAnchor)
        ])
      
        // Close Button
        addSubview(closeButton)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            closeButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            closeButton.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
        
        // Seperator
        addSubview(seperatorLine)
        seperatorLine.backgroundColor = .tertiarySystemGroupedBackground
        seperatorLine.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            seperatorLine.leadingAnchor.constraint(equalTo: leadingAnchor),
            seperatorLine.trailingAnchor.constraint(equalTo: trailingAnchor),
            seperatorLine.bottomAnchor.constraint(equalTo: bottomAnchor),
            seperatorLine.heightAnchor.constraint(equalToConstant: 0.75)
        ])
    }
    
    // Effects
    private func titleDidUpdate() {
        self.titleLabel.text = self.titleText ?? ""
    }
    
    private func backButtonVisibilityDidChange() {
        if let hasBackButton, hasBackButton {
            self.backButton.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
            self.backButton.alpha = 0
            self.backButton.isHidden = false
            self.titleLeadingConstraint.isActive = false
            self.titleLeadingConstraint = titleLabel.centerXAnchor.constraint(equalTo: centerXAnchor)
            self.titleLeadingConstraint.isActive = true
            
            UIView.animate(withDuration: 0.25, animations: {
                self.backButton.transform = CGAffineTransform(scaleX: 1, y: 1)
                self.backButton.alpha = 1
                self.layoutIfNeeded()
            })
        } else {
            self.titleLeadingConstraint.isActive = false
            self.titleLeadingConstraint = titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor)
            self.titleLeadingConstraint.isActive = true
            
            UIView.animate(withDuration: 0.25, animations: {
                self.backButton.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
                self.backButton.alpha = 0
                self.layoutIfNeeded()
            }, completion: { _ in
                self.backButton.isHidden = true
            })
        }
    }
    
    @objc private func onClosePress() {
        self.onClose?()
    }
    
    @objc private func onBackPress() {
        self.onBack?()
    }
}
