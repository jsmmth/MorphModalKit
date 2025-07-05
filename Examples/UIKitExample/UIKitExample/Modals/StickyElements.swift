//
//  StickyElements.swift
//  UIKitExample
//
//  Created by Joseph Smith on 05/07/2025.
//

import UIKit
import MorphModalKit

private extension UIButton {
  static func navButton(
    title: String,
    textColor: UIColor = UIColor(red: 0.25, green: 0.25, blue: 0.25, alpha: 1)
  ) -> UIButton {
      var cfg = UIButton.Configuration.plain()
      cfg.title = title.uppercased()
      cfg.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
        var out = incoming
        out.font = .rounded(ofSize: 12, weight: .heavy)
        out.foregroundColor = textColor
        return out
      }
      cfg.contentInsets = .init(top: 4, leading: 8, bottom: 4, trailing: 8)
      let btn = UIButton(configuration: cfg)
      btn.backgroundColor = UIColor(red: 0.95, green: 0.95, blue: 0.95, alpha: 1)
      btn.layer.cornerRadius = 12
      btn.layer.cornerCurve = .continuous
      btn.clipsToBounds = true
      btn.translatesAutoresizingMaskIntoConstraints = false
      return btn
  }
}

class StickyElements: StickyElementsContainer {
    private weak var current: MorphModal?
    private let backBtn = UIButton.navButton(title: "Back")
    private let nextBtn = UIButton.navButton(title: "Next")
    private let gradientContainer = UIView()
    private let titleLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = .systemFont(ofSize: 17, weight: .bold)
        lbl.textColor = .label
        lbl.numberOfLines = 0
        return lbl
    }()
    private let handlebar = UIView()
    private let stackView = UIStackView()

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
        
        handlebar.backgroundColor = UIColor(red: 0.95, green: 0.95, blue: 0.95, alpha: 1)
        handlebar.layer.cornerCurve = .continuous
        handlebar.layer.cornerRadius = 2
        handlebar.translatesAutoresizingMaskIntoConstraints = false
        
        titleLabel.text = "Sticky"
        backBtn.addTarget(self, action: #selector(onBack), for: .touchUpInside)
        nextBtn.addTarget(self, action: #selector(onNext), for: .touchUpInside)

        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .equalSpacing
        stackView.translatesAutoresizingMaskIntoConstraints = false
        [backBtn, titleLabel, nextBtn].forEach(stackView.addArrangedSubview)
        
        addSubview(handlebar)
        addSubview(stackView)
        
        NSLayoutConstraint.activate([
            handlebar.widthAnchor.constraint(equalToConstant: 52),
            handlebar.heightAnchor.constraint(equalToConstant: 4),
            handlebar.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            handlebar.centerXAnchor.constraint(equalTo: centerXAnchor),
            
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            stackView.topAnchor.constraint(equalTo: handlebar.bottomAnchor, constant: 12)
        ])
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let gradient = CAGradientLayer()
        gradient.colors = [
            UIColor.systemBackground.cgColor,
            UIColor.systemBackground.withAlphaComponent(0).cgColor
        ]
        gradient.startPoint = CGPoint(x: 0.5, y: 0.0)
        gradient.endPoint = CGPoint(x: 0.5, y: 1.0)
        gradient.frame = gradientContainer.bounds
        gradientContainer.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
        gradientContainer.layer.insertSublayer(gradient, at: 0)
    }
    
    // show only stack view for morph modals
    override func contextDidChange(to newOwner: ModalView, from _: ModalView?, animated: Bool) {
        current = newOwner as? MorphModal
        let visible = current != nil
        let update = { self.stackView.alpha = visible ? 1 : 0 }
        animated ? UIView.animate(withDuration: 0.20, animations: update) : update()
        
        guard let step = current?.step else { return }
        let newText: String
        switch step {
        case .one:   newText = "Sticky"
        case .two:   newText = "Also"
        case .three: newText = "Morphs"
        }
        
        // Could add some sort of text transition
        self.titleLabel.text = newText
    }

    @objc private func onBack() {
        guard let page = current else { return }
        switch page.step {
        case .one: modalVC.replace(with: MenuModal(), direction: .backward)
        case .two: modalVC.replace(with: MorphModal(step: .one), direction: .backward)
        case .three: modalVC.replace(with: MorphModal(step: .two), direction: .backward)
        }
    }

    @objc private func onNext() {
        guard let page = current else { return }
        switch page.step {
        case .one: modalVC.replace(with: MorphModal(step: .two), direction: .forward)
        case .two: modalVC.replace(with: MorphModal(step: .three), direction: .forward)
        case .three: modalVC.replace(with: MenuModal(), direction: .forward)
        }
    }
}
