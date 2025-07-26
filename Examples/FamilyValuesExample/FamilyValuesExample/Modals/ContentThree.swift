//
//  ContentThree.swift
//  FamilyValuesExample
//
//  Created by Joseph Smith on 26/07/2025.
//

import UIKit
import MorphModalKit

class ContentThree: UIViewController, ModalView {
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Another heading"
        label.font = .systemFont(ofSize: 21, weight: .bold)
        label.textAlignment = .left
        return label
    }()
    
    private let bodyText: UILabel = {
        let label = UILabel()
        label.text = "Lorem ipsum dolor amet. Lorem ipsum dolor amet. Lorem ipsum dolor amet. Lorem ipsum dolor amet. Lorem ipsum dolor amet.\n\nThis is some example text that spans over multiple lines. Bla bla bla test test test many words. This is a new sentance and we'll see how that fares too."
        label.font = .systemFont(ofSize: 17, weight: .regular)
        label.textAlignment = .left
        label.numberOfLines = 0
        return label
    }()
    
    private let textContainer: UIStackView = {
        let view = UIStackView()
        view.axis = .vertical
        view.spacing = 16
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        textContainer.addArrangedSubview(titleLabel)
        textContainer.addArrangedSubview(bodyText)
        view.addSubview(textContainer)
        
        NSLayoutConstraint.activate([
            textContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            textContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            textContainer.topAnchor.constraint(equalTo: view.topAnchor, constant: 104),
        ])
    }

    func preferredHeight(for _: CGFloat) -> CGFloat { 430 }
}
