//
//  ExampleModalFlow.swift
//  UIKitExample
//
//  Created by Joseph Smith on 05/07/2025.
//
import UIKit
import MorphModalKit

private extension UIView {
    func addEmbedded(_ sub: UIView...) {
        sub.forEach { $0.translatesAutoresizingMaskIntoConstraints = false; addSubview($0) }
    }
    var owningVC: UIViewController? {
        sequence(first: next) { $0?.next }.first { $0 is UIViewController } as? UIViewController
    }
}

final class CenterColumn: UIStackView {
    init(spacing: CGFloat = 8, align: UIStackView.Alignment = .fill) {
        super.init(frame: .zero)
        axis = .vertical
        alignment = align
        distribution = .equalSpacing
        self.spacing = spacing
        translatesAutoresizingMaskIntoConstraints = false
    }
    required init(coder: NSCoder) { fatalError() }
}

extension UIButton {
    static func styled(
        title: String,
        bgColor: UIColor = .black,
        fgColor: UIColor = .white,
        cornerRadius: CGFloat = 16,
        height: CGFloat = 48
    ) -> UIButton {
        var config = UIButton.Configuration.filled()
        config.title = title
        config.baseBackgroundColor = bgColor
        config.baseForegroundColor = fgColor
        config.contentInsets = .init(top: 0, leading: 0, bottom: 0, trailing: 0)

        let button = UIButton(configuration: config)
        button.layer.cornerRadius = cornerRadius
        button.layer.cornerCurve = .continuous
        button.clipsToBounds = true
        button.translatesAutoresizingMaskIntoConstraints = false
        button.heightAnchor.constraint(equalToConstant: height).isActive = true
        return button
    }
}

private extension UIButton {
    convenience init(_ title: String) {
        self.init(type: .system)
        setTitle(title, for: .normal)
        titleLabel?.font = .preferredFont(forTextStyle: .title3)
    }
}

extension UIViewController {
    var modalHost: ModalViewController? {
        sequence(first: parent) { $0?.parent }.first { $0 is ModalViewController } as? ModalViewController
    }
}

class StickyElements: StickyElementsContainer {
    private weak var current: MorphModal?
    private let back = UIButton(configuration: .plain())
    private let nextBtn = UIButton.styled(title: "Next")
    private let handlebar = UIView()

    override init(frame: CGRect = .zero) {
        super.init(frame: frame)
        
        handlebar.backgroundColor = .systemGray6
        handlebar.layer.cornerCurve = .continuous
        handlebar.layer.cornerRadius = 2
        
        back.configuration?.title = "← Back"
        back.tintColor = .black
        back.addTarget(self, action: #selector(onBack), for: .touchUpInside)
        nextBtn.addTarget(self, action: #selector(onNext), for: .touchUpInside)

        addEmbedded(back, nextBtn, handlebar)
        NSLayoutConstraint.activate([
            handlebar.widthAnchor.constraint(equalToConstant: 44),
            handlebar.heightAnchor.constraint(equalToConstant: 4),
            handlebar.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            handlebar.centerXAnchor.constraint(equalTo: centerXAnchor),
            
            back.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            back.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            
            nextBtn.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            nextBtn.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            nextBtn.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16)
        ])
    }
    required init?(coder: NSCoder) { fatalError() }

    // show only for Morph pages
    override func contextDidChange(to newOwner: ModalView, from _: ModalView?, animated: Bool) {
        current = newOwner as? MorphModal
        let visible = current != nil
        nextBtn.setTitle((current?.step == .three) ? "Done ✓" : "Next →", for: .normal)
        let update = { self.back.alpha = visible ? 1 : 0; self.nextBtn.alpha = visible ? 1 : 0 }
        animated ? UIView.animate(withDuration: 0.20, animations: update) : update()
    }

    @objc private func onBack() {
        guard let page = current, let host = wrapper?.owningVC as? ModalViewController else { return }
        switch page.step {
        case .one:   host.replace(with: MenuModal(), direction: .backward)
        case .two:   host.replace(with: MorphModal(step: .one), direction: .backward)
        case .three: host.replace(with: MorphModal(step: .two), direction: .backward)
        }
    }

    @objc private func onNext() {
        guard let page = current, let host = wrapper?.owningVC as? ModalViewController else { return }
        switch page.step {
        case .one:   host.replace(with: MorphModal(step: .two), direction: .forward)
        case .two:   host.replace(with: MorphModal(step: .three), direction: .forward)
        case .three: host.replace(with: MenuModal(), direction: .forward)
        }
    }
}

final class MenuModal: UIViewController, ModalView {
    private let stackBtn = UIButton.styled(title: "Push")
    private let popBtn = UIButton.styled(title: "Pop")
    private let morphBtn = UIButton.styled(title: "Replace (Morph)")
    private let inputBtn = UIButton.styled(title: "Input")
    private let listBtn  = UIButton.styled(title: "Scroll View")

    override func viewDidLoad() {
        super.viewDidLoad()

        let col = CenterColumn()
        [stackBtn, popBtn, morphBtn, inputBtn, listBtn].forEach(col.addArrangedSubview)
        view.addEmbedded(col)
        NSLayoutConstraint.activate([
            col.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            col.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            col.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])

        popBtn.addTarget(self, action: #selector(popModal), for: .touchUpInside)
        stackBtn.addTarget(self, action: #selector(pushAnotherMenu), for: .touchUpInside)
        morphBtn.addTarget(self, action: #selector(openMorph),       for: .touchUpInside)
        inputBtn.addTarget(self, action: #selector(openInput),       for: .touchUpInside)
        listBtn .addTarget(self, action: #selector(openList),        for: .touchUpInside)
    }

    // MARK: navigation
    @objc private func pushAnotherMenu() { modalHost?.push(MenuModal(), sticky: StickyElements()) }
    @objc private func popModal() { modalHost?.pop() }
    @objc private func openMorph() { modalHost?.replace(with: MorphModal(step: .one)) }
    @objc private func openInput() { modalHost?.push(InputModal(), sticky: StickyElements()) }
    @objc private func openList()  { modalHost?.push(ScrollModal(), sticky: StickyElements()) }
    func preferredHeight(for _: CGFloat) -> CGFloat { 320 }
}

enum MorphStep: Int { case one = 1, two, three }
final class MorphModal: UIViewController, ModalView {
    let step: MorphStep
    private let morphContainer = UIView()
    
    init(step: MorphStep) { self.step = step; super.init(nibName: nil, bundle: nil) }
    required init?(coder: NSCoder) { fatalError() }

    private let titleLbl = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        morphContainer.backgroundColor = .systemGray6
        morphContainer.layer.cornerCurve = .continuous
        morphContainer.layer.cornerRadius = 16
        
        titleLbl.font = .preferredFont(forTextStyle: .largeTitle)
        titleLbl.textAlignment = .center
        
        view.addEmbedded(morphContainer)
        morphContainer.addEmbedded(titleLbl)
        NSLayoutConstraint.activate([
            morphContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            morphContainer.topAnchor.constraint(equalTo: view.topAnchor, constant: 48),
            morphContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -70),
            morphContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            titleLbl.centerYAnchor.constraint(equalTo: morphContainer.centerYAnchor),
            titleLbl.centerXAnchor.constraint(equalTo: morphContainer.centerXAnchor)
        ])
        
        titleLbl.text = "Morph \(step.rawValue)"
    }

    func preferredHeight(for _: CGFloat) -> CGFloat {
        switch step { case .one: 300; case .two: 380; case .three: 460 }
    }
}

final class ScrollModal: UIViewController, ModalView {
    private let scroll = UIScrollView()
    private let stack  = UIStackView()
    var dismissalHandlingScrollView: UIScrollView? { scroll }

    override func viewDidLoad() {
        super.viewDidLoad()

        scroll.alwaysBounceVertical = true
        view.addEmbedded(scroll)
        NSLayoutConstraint.activate([
            scroll.leadingAnchor .constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scroll.topAnchor     .constraint(equalTo: view.topAnchor),
            scroll.bottomAnchor  .constraint(equalTo: view.bottomAnchor)
        ])

        stack.axis = .vertical; stack.spacing = 12; scroll.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false

        (1...40).forEach {
            let lbl = UILabel()
            lbl.text = "Item \($0)"
            lbl.textAlignment = .center
            lbl.font = .preferredFont(forTextStyle: .title3)
            stack.addArrangedSubview(lbl)
        }

        NSLayoutConstraint.activate([
            stack.leadingAnchor .constraint(equalTo: scroll.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: scroll.trailingAnchor),
            stack.widthAnchor   .constraint(equalTo: scroll.widthAnchor),
            stack.topAnchor     .constraint(equalTo: scroll.topAnchor, constant: 20),
            stack.bottomAnchor  .constraint(equalTo: scroll.bottomAnchor, constant: -20)
        ])
    }

    func preferredHeight(for _: CGFloat) -> CGFloat { 500 }
}

final class InputModal: UIViewController, ModalView {

    private let tf = UITextField()

    override func viewDidLoad() {
        super.viewDidLoad()

        let tip = UILabel()
        tip.text = "When keyboard is shown\nview is resized if needed."
        tip.numberOfLines = 2
        tip.font = .preferredFont(forTextStyle: .callout)
        tip.textColor = .secondaryLabel

        tf.borderStyle = .roundedRect
        tf.placeholder = "Type something…"

        let col = CenterColumn(spacing: 16, align: .center)
        col.addArrangedSubview(tip)
        col.addArrangedSubview(tf)

        view.addEmbedded(col)
        NSLayoutConstraint.activate([
            tf.widthAnchor.constraint(equalTo: col.widthAnchor, multiplier: 0.8),
            col.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            col.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    func modalWillDisappear() { tf.resignFirstResponder() }
    func preferredHeight(for _: CGFloat) -> CGFloat { 500 }
}
