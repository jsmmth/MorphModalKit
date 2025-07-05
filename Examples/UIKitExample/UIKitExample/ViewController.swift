//
//  ViewController.swift
//  UIKitExample
//
//  Created by Joseph Smith on 05/07/2025.
//

import UIKit
import MorphModalKit

class ViewController: UIViewController {
    private let host = ModalViewController()
    private let presentButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Present Modal", for: .normal)
        return button
    }()
    
    override func viewDidLoad() {
        presentButton.addTarget(self, action: #selector(onPresentPress), for: .touchUpInside)
        view.addSubview(presentButton)
        presentButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            presentButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            presentButton.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    @objc private func onPresentPress() {
        self.presentModal(MenuModal(), sticky: MorphHeaderSticky())
    }
}

