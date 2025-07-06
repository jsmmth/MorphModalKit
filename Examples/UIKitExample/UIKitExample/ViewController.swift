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
    textColor: UIColor = .label
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
      btn.backgroundColor = .systemGray6
      btn.layer.cornerRadius = 12
      btn.layer.cornerCurve = .continuous
      btn.clipsToBounds = true
      btn.translatesAutoresizingMaskIntoConstraints = false
      return btn
  }
}

class ViewController: UIViewController {
    private let presentButton = UIButton.sampleButton(title: "MorphModalKit")
    private let icon: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        view.image = UIImage(named: "icon")
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    override func viewDidLoad() {
        view.backgroundColor = .systemBackground
        
        view.addSubview(icon)
        view.addSubview(presentButton)
        
        presentButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            presentButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            presentButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            icon.widthAnchor.constraint(equalToConstant: 60),
            icon.heightAnchor.constraint(equalToConstant: 60),
            icon.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            icon.bottomAnchor.constraint(equalTo: presentButton.topAnchor, constant: -16),
        ])
        
        presentButton.addTarget(self, action: #selector(onPresentPress), for: .touchUpInside)
    }
    
    @objc private func onPresentPress() {
        var options: ModalOptions = ModalOptions.default
        
        options.enableGlass = true
        
        // Example, full width modal
        // options.horizontalInset = 0
        // options.bottomSpacing = 0
        // options.cornerMask = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        
        self.presentModal(MenuModal(), options: options, sticky: StickyElements.self)
    }
}

