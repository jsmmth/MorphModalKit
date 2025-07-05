//
//  InputModal.swift
//  UIKitExample
//
//  Created by Joseph Smith on 05/07/2025.
//

import UIKit
import MorphModalKit

class InputModal: UIViewController, ModalView {
    private let tf = UITextField()

    override func viewDidLoad() {
        super.viewDidLoad()
        tf.borderStyle = .none
        tf.font = .rounded(ofSize: 24, weight: .medium)
        tf.tintColor = UIColor(displayP3Red: 0.36, green: 0.12, blue: 0.93, alpha: 1)
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.textAlignment = .center
        tf.placeholder = "Tap to show keyboard"
        
        view.addSubview(tf)
        
        NSLayoutConstraint.activate([
            tf.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
            tf.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            tf.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
//    func modalWillAppear() { tf.becomeFirstResponder() }
    func modalWillDisappear() { tf.resignFirstResponder() }
    func preferredHeight(for _: CGFloat) -> CGFloat { 500 } // This will get shrunk when the keyboard shows
}
