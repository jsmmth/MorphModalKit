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
    textColor: UIColor = .label
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
      btn.backgroundColor = .tertiarySystemGroupedBackground
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
    private let titleLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = .systemFont(ofSize: 17, weight: .bold)
        lbl.textColor = .label
        lbl.numberOfLines = 0
        return lbl
    }()
    private let stackView = UIStackView()

    required init(modalVC: ModalViewController) {
        super.init(modalVC: modalVC)
        
        titleLabel.text = "Sticky"
        backBtn.addTarget(self, action: #selector(onBack), for: .touchUpInside)
        nextBtn.addTarget(self, action: #selector(onNext), for: .touchUpInside)

        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .equalSpacing
        stackView.translatesAutoresizingMaskIntoConstraints = false
        [backBtn, titleLabel, nextBtn].forEach(stackView.addArrangedSubview)
        addSubview(stackView)
    
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: 24)
        ])
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    override func contextDidChange(to newOwner: ModalView, from _: ModalView?, animated: Bool) {
        // show only stack view for morph modals
        // This is an example of how I only show the stack view when I get a ModalView of MorphModal
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
