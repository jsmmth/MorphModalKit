//
//  IconButton.swift
//  FamilyValuesExample
//
//  Created by Joseph Smith on 26/07/2025.
//

import UIKit

/// Example Icon Button component
/// Again this is a very basic example component. Realistically you'd want
/// - Dynamic sizing
/// - Dynamic styling
/// - Ability to transition and animate icon changes etc
/// This is just used as a POC

class IconButton: Button {
    private let iconView = UIImageView()
    private let icon: String
    
    required init(icon: String) {
        self.icon = icon
        super.init(frame: .zero)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        self.widthAnchor.constraint(equalToConstant: 40).isActive = true
        self.heightAnchor.constraint(equalToConstant: 40).isActive = true
        self.backgroundColor = .tertiarySystemGroupedBackground
        self.layer.cornerCurve = .circular
        self.layer.cornerRadius = 20
        
        let config = UIImage.SymbolConfiguration(pointSize: 15, weight: .heavy)
        let image = UIImage(systemName: icon, withConfiguration: config)?.withRenderingMode(.alwaysTemplate)
        iconView.image = image
        iconView.tintColor = .systemGray
        iconView.contentMode = .center
        iconView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(iconView)
        NSLayoutConstraint.activate([
            iconView.centerXAnchor.constraint(equalTo: centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
}
