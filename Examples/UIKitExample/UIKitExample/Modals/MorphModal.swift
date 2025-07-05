//
//  MorphModal.swift
//  UIKitExample
//
//  Created by Joseph Smith on 05/07/2025.
//

import UIKit
import MorphModalKit

enum MorphStep: Int { case one = 1, two, three }
final class MorphModal: UIViewController, ModalView {
    let step: MorphStep
    private let morphContainer = UIView()
    init(step: MorphStep) { self.step = step; super.init(nibName: nil, bundle: nil) }
    required init?(coder: NSCoder) { fatalError() }
    private let titleLbl = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        morphContainer.backgroundColor = UIColor(red: 0.95, green: 0.95, blue: 0.95, alpha: 1)
        morphContainer.layer.cornerCurve = .continuous
        morphContainer.layer.cornerRadius = 20
        morphContainer.translatesAutoresizingMaskIntoConstraints = false
        
        titleLbl.font = .rounded(ofSize: 17, weight: .medium)
        titleLbl.textAlignment = .center
        titleLbl.textColor = .label
        titleLbl.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(morphContainer)
        morphContainer.addSubview(titleLbl)
        
        NSLayoutConstraint.activate([
            morphContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            morphContainer.topAnchor.constraint(equalTo: view.topAnchor, constant: 60),
            morphContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20),
            morphContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            titleLbl.centerYAnchor.constraint(equalTo: morphContainer.centerYAnchor),
            titleLbl.centerXAnchor.constraint(equalTo: morphContainer.centerXAnchor)
        ])
        
        switch step {
        case .one:
            titleLbl.text = "Oh hi"
        case .two:
            titleLbl.text = "Guess what"
        case .three:
            titleLbl.text = "I'm morphing!"
        }
    }

    func preferredHeight(for _: CGFloat) -> CGFloat {
        switch step {
        case .one: 346
        case .two: 269
        case .three: 543
        }
    }
}
