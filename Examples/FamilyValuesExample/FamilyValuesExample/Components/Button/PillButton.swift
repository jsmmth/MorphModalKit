//
//  PillButton.swift
//  FamilyValuesExample
//
//  Created by Joseph Smith on 26/07/2025.
//

import UIKit

/// Example Pill Button component
/// Again this is a very basic example component you'll want to build out a proper button component
/// This is just used as a POC

enum PillButtonStyle {
    case primary
    case secondary
    
    var backgroundColor: UIColor {
        switch self {
        case .primary:
            return .label
        case .secondary:
            return .tertiarySystemGroupedBackground
        }
    }
    
    var textColor: UIColor {
        switch self {
        case .primary:
            return .systemBackground
        case .secondary:
            return .label
        }
    }
}

class PillButton: Button {
    public var style: PillButtonStyle = .primary {
        didSet {
            styleDidUpdate()
        }
    }
    public var contentText: String {
        didSet {
            contentDidUpdate()
        }
    }
    
    private let horizontalPadding: CGFloat = 24
    private let textLabel: AnimatedUILabel = {
        let label = AnimatedUILabel()
        label.font = .systemFont(ofSize: 18, weight: .semibold)
        label.textColor = .systemBackground
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    required init(contentText: String) {
        self.contentText = contentText
        super.init(frame: .zero)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        self.heightAnchor.constraint(equalToConstant: 48).isActive = true
        self.backgroundColor = .label
        self.layer.cornerCurve = .continuous
        self.layer.cornerRadius = 24
        
        addSubview(textLabel)
        NSLayoutConstraint.activate([
            textLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            textLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
        ])
        textLabel.text = contentText
    }
    
    private func contentDidUpdate() {
        self.textLabel.text = self.contentText
    }
    
    private func styleDidUpdate() {
        self.textLabel.textColor = style.textColor
        self.backgroundColor = style.backgroundColor
    }
}
