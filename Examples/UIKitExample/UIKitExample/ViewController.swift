//
//  ViewController.swift
//  UIKitExample
//
//  Created by Joseph Smith on 05/07/2025.
//

import UIKit
import MorphModalKit

private extension UIButton {
  static func sampleButton(
    title: String,
    textColor: UIColor = UIColor(red: 0.25, green: 0.25, blue: 0.25, alpha: 1)
  ) -> UIButton {
      var cfg = UIButton.Configuration.plain()
      cfg.title = title
      cfg.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
        var out = incoming
        out.font = .rounded(ofSize: 15, weight: .bold)
        out.foregroundColor = textColor
        return out
      }
      cfg.contentInsets = .init(top: 8, leading: 16, bottom: 8, trailing: 16)
      let btn = UIButton(configuration: cfg)
      btn.backgroundColor = UIColor(red: 0.95, green: 0.95, blue: 0.95, alpha: 1)
      btn.layer.cornerRadius = 12
      btn.layer.cornerCurve = .continuous
      btn.clipsToBounds = true
      btn.translatesAutoresizingMaskIntoConstraints = false
      return btn
  }
}

class ViewController: UIViewController {
    private let host = ModalViewController()
    private let presentButton = UIButton.sampleButton(title: "MorphModalKit")
    
    override func viewDidLoad() {
        view.backgroundColor = .white
        presentButton.addTarget(self, action: #selector(onPresentPress), for: .touchUpInside)
        view.addSubview(presentButton)
        presentButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            presentButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            presentButton.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    @objc private func onPresentPress() {
        self.presentModal(MenuModal(), sticky: StickyElements.self)
    }
}

