//
//  MenuModal.swift
//  UIKitExample
//
//  Created by Joseph Smith on 05/07/2025.
//

import UIKit
import MorphModalKit

private extension UIButton {
  static func menuTile(
    title: String,
    symbol: String,
    iconColor: UIColor = .label,
    textColor: UIColor = .systemGray
  ) -> UIButton {
      var cfg = UIButton.Configuration.plain()
      let symCfg = UIImage.SymbolConfiguration(pointSize: 20, weight: .bold)
      cfg.image = UIImage(systemName: symbol, withConfiguration: symCfg)
      cfg.imagePlacement = .top
      cfg.imagePadding = 16
      cfg.imageColorTransformer = UIConfigurationColorTransformer { _ in iconColor }
      cfg.title = title.uppercased()
      cfg.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
        var out = incoming
        out.font = .rounded(ofSize: 12, weight: .heavy)
        out.foregroundColor = textColor
        return out
      }
      let btn = UIButton(configuration: cfg)
      btn.backgroundColor = .tertiarySystemGroupedBackground
      btn.layer.cornerRadius = 4
      btn.layer.cornerCurve = .continuous
      btn.clipsToBounds = true
      btn.translatesAutoresizingMaskIntoConstraints = false
      let square = btn.heightAnchor.constraint(equalTo: btn.widthAnchor)
      square.priority = .defaultHigh
      square.isActive = true
      return btn
  }
}

class MenuModal: UIViewController, ModalView {
    private lazy var pushBtn  = UIButton.menuTile(title: "Push", symbol: "arrow.up.right")
    private lazy var popBtn   = UIButton.menuTile(title: "Pop", symbol: "arrow.down")
    private lazy var morphBtn = UIButton.menuTile(title: "Morph", symbol: "cube.transparent.fill")
    private lazy var inputBtn = UIButton.menuTile(title: "Input", symbol: "signature")
    private lazy var listBtn  = UIButton.menuTile(title: "Scroll", symbol: "scroll.fill")
    private lazy var closeBtn = UIButton.menuTile(title: "Close", symbol: "xmark")
    private let container = UIView()
    private let col = UIStackView()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let rows: [[UIButton]] = [
            [pushBtn,  popBtn],
            [morphBtn, inputBtn],
            [listBtn,  closeBtn]
        ]
        
        // Container
        container.layer.cornerCurve = .continuous
        container.layer.cornerRadius = 20
        container.clipsToBounds = true
        container.translatesAutoresizingMaskIntoConstraints = false
        
        // Buttons
        col.axis = .vertical
        col.spacing = 4
        col.distribution = .fillEqually
        col.translatesAutoresizingMaskIntoConstraints = false
        rows.forEach { row in
            let h = UIStackView(arrangedSubviews: row)
            h.axis = .horizontal
            h.spacing = 4
            h.distribution = .fillEqually
            col.addArrangedSubview(h)
        }
        
        view.addSubview(container)
        container.addSubview(col)
        NSLayoutConstraint.activate([
            container.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            container.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            container.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            container.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20),
            
            col.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            col.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            col.topAnchor.constraint(equalTo: container.topAnchor),
            col.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        // Actions
        pushBtn .addTarget(self, action: #selector(pushAnotherMenu), for: .touchUpInside)
        popBtn  .addTarget(self, action: #selector(popModal),        for: .touchUpInside)
        morphBtn.addTarget(self, action: #selector(openMorph),       for: .touchUpInside)
        inputBtn.addTarget(self, action: #selector(openInput),       for: .touchUpInside)
        listBtn .addTarget(self, action: #selector(openList),        for: .touchUpInside)
        closeBtn.addTarget(self, action: #selector(closeFlow),       for: .touchUpInside)
    }

    // MARK: Navigation
    @objc private func pushAnotherMenu() { modalVC?.push(MenuModal(), sticky: StickyElements.self) }
    @objc private func popModal() { modalVC?.pop() }
    @objc private func openMorph() { modalVC?.replace(with: MorphModal(step: .one)) }
    @objc private func openInput() { modalVC?.push(InputModal(),   sticky: StickyElements.self) }
    @objc private func openList() { modalVC?.push(ScrollModal(),  sticky: StickyElements.self) }
    @objc private func closeFlow() { modalVC?.hide() }

    func preferredHeight(for _: CGFloat) -> CGFloat { 324 }
}
