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
    init(spacing: CGFloat = 24) {
        super.init(frame: .zero)
        axis = .vertical; alignment = .center; distribution = .equalSpacing
        self.spacing = spacing
        translatesAutoresizingMaskIntoConstraints = false
    }
    required init(coder: NSCoder) { fatalError() }
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

class MorphHeaderSticky: StickyElementsContainer {
    private weak var current: MorphPage?
    private let back = UIButton(configuration: .plain())
    private let nextBtn = UIButton(configuration: .plain())

    override init(frame: CGRect = .zero) {
        super.init(frame: frame)

        back.configuration?.title = "← Back"
        back.tintColor = .black
        back.addTarget(self, action: #selector(onBack), for: .touchUpInside)

        nextBtn.tintColor = .black
        nextBtn.addTarget(self, action: #selector(onNext), for: .touchUpInside)

        addEmbedded(back, nextBtn)
        NSLayoutConstraint.activate([
            back.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            back.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            nextBtn.centerXAnchor.constraint(equalTo: centerXAnchor),
            nextBtn.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12)
        ])
    }
    required init?(coder: NSCoder) { fatalError() }

    // show only for Morph pages
    override func contextDidChange(to newOwner: ModalView, from _: ModalView?, animated: Bool) {
        current = newOwner as? MorphPage
        let visible = current != nil
        nextBtn.setTitle((current?.step == .three) ? "Done ✓" : "Next →", for: .normal)
        let update = { self.back.alpha = visible ? 1 : 0; self.nextBtn.alpha = visible ? 1 : 0 }
        animated ? UIView.animate(withDuration: 0.20, animations: update) : update()
    }

    @objc private func onBack() {
        guard let page = current, let host = wrapper?.owningVC as? ModalViewController else { return }
        switch page.step {
        case .one:   host.replace(with: MenuModal(),           direction: .backward)
        case .two:   host.replace(with: MorphPage(step: .one), direction: .backward)
        case .three: host.replace(with: MorphPage(step: .two), direction: .backward)
        }
    }

    @objc private func onNext() {
        guard let page = current, let host = wrapper?.owningVC as? ModalViewController else { return }
        switch page.step {
        case .one:   host.replace(with: MorphPage(step: .two),   direction: .forward)
        case .two:   host.replace(with: MorphPage(step: .three), direction: .forward)
        case .three: host.replace(with: MenuModal(),             direction: .forward)
        }
    }
}

final class MenuModal: UIViewController, ModalView {
    private let stackBtn = UIButton("Push stack")
    private let morphBtn = UIButton("Morph flow →")
    private let inputBtn = UIButton("Text input")
    private let listBtn  = UIButton("Scrollable list")

    override func viewDidLoad() {
        super.viewDidLoad()

        let col = CenterColumn()
        [stackBtn, morphBtn, inputBtn, listBtn].forEach(col.addArrangedSubview)
        view.addEmbedded(col)
        NSLayoutConstraint.activate([
            col.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            col.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])

        stackBtn.addTarget(self, action: #selector(pushAnotherMenu), for: .touchUpInside)
        morphBtn.addTarget(self, action: #selector(openMorph),       for: .touchUpInside)
        inputBtn.addTarget(self, action: #selector(openInput),       for: .touchUpInside)
        listBtn .addTarget(self, action: #selector(openList),        for: .touchUpInside)
    }

    // MARK: navigation
    @objc private func pushAnotherMenu() { modalHost?.push(MenuModal(), sticky: MorphHeaderSticky()) }

    @objc private func openMorph() {
        modalHost?.replace(with: MorphPage(step: .one))
    }

    @objc private func openInput() { modalHost?.push(InputPage()) }
    @objc private func openList()  { modalHost?.push(ScrollPage()) }

    func preferredHeight(for _: CGFloat) -> CGFloat { 320 }
}

enum MorphStep: Int { case one = 1, two, three }
final class MorphPage: UIViewController, ModalView {

    let step: MorphStep
    init(step: MorphStep) { self.step = step; super.init(nibName: nil, bundle: nil) }
    required init?(coder: NSCoder) { fatalError() }

    private let titleLbl = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        titleLbl.font = .preferredFont(forTextStyle: .largeTitle)
        titleLbl.textAlignment = .center

        view.addEmbedded(titleLbl)
        NSLayoutConstraint.activate([
            titleLbl.topAnchor.constraint(equalTo: view.topAnchor, constant: 60),
            titleLbl.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
        titleLbl.text = "Morph \(step.rawValue)"
    }

    func preferredHeight(for _: CGFloat) -> CGFloat {
        switch step { case .one: 300; case .two: 380; case .three: 460 }
    }
}

final class ScrollPage: UIViewController, ModalView {

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

final class InputPage: UIViewController, ModalView {

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

        let col = CenterColumn(spacing: 16)
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
