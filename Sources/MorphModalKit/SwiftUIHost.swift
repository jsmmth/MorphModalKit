// SwiftUIHost.swift
// MorphModalKit
//
// Created by Joseph Smith on 08/07/2025.

import SwiftUI
import UIKit
import ObjectiveC

/// So we can call `StickyView()` on a generic.
public protocol DefaultConstructible {
    init()
}

fileprivate protocol _Pending {
    func commit()
}

/// Common builder for both present & push
public class PendingModal<Content: MorphModalContent & View>: _Pending {
    private let manager: MorphModalManager
    private var content: Content
    private let isPush: Bool

    /// Capture everything, but don’t run until the next run‐loop tick
    init(
        _ content: Content,
        manager: MorphModalManager,
        pushInsteadOfPresent: Bool
    ) {
        self.content = content
        self.manager = manager
        self.isPush  = pushInsteadOfPresent

        // schedule for after any further `.withXXX` calls
        DispatchQueue.main.async {
            self.commit()
        }
    }

    @discardableResult
    public func withSticky<S: View & DefaultConstructible>(
        _ stickyView: S.Type
    ) -> PendingModal {
        var cfg = content.modalConfig
        cfg.sticky = .sticky(SwiftUIStickyContainer<S>.self)
        content.modalConfig = cfg
        return self
    }

    @discardableResult
    public func inheritSticky() -> PendingModal {
        var cfg = content.modalConfig
        cfg.sticky = .inherit
        content.modalConfig = cfg
        return self
    }

    @discardableResult
    public func noSticky() -> PendingModal {
        var cfg = content.modalConfig
        cfg.sticky = .none
        content.modalConfig = cfg
        return self
    }

    @discardableResult
    public func withOptions(
        _ mutate: (inout ModalOptions) -> Void
    ) -> PendingModal {
        var cfg = content.modalConfig
        mutate(&cfg.options)
        content.modalConfig = cfg
        return self
    }

    @discardableResult
    public func showsOverlay(_ show: Bool) -> PendingModal {
        var cfg = content.modalConfig
        cfg.showsOverlay = show
        content.modalConfig = cfg
        return self
    }

    @discardableResult
    public func animated(_ a: Bool) -> PendingModal {
        var cfg = content.modalConfig
        cfg.animated = a
        content.modalConfig = cfg
        return self
    }

    /// Final commit; called automatically once the current run-loop drains.
    @MainActor
    func commit() {
        if isPush {
            manager._push(content)
        } else {
            manager._present(content)
        }
    }
}

@MainActor
public final class MorphModalManager: ObservableObject {
    fileprivate weak var controller: ModalViewController?

    /// The current front‐most ModalView (used by your sticky container)
    @Published public var currentFrontModal: ModalView? = nil

    public init() {}

    func attach(_ host: ModalViewController) {
        self.controller = host
        host.swiftModalManager = self
    }

    public func refreshScrollBinding() {
        controller?.refreshScrollDismissBinding()
    }

    /// Immediately present
    public func present<Content: MorphModalContent & View>(
        _ content: Content
    ) {
        _present(content)
    }

    /// Immediately push
    public func push<Content: MorphModalContent & View>(
        _ content: Content
    ) {
        _push(content)
    }

    /// Pop / hide / replace are unchanged
    public func pop(animated: Bool = true) {
        controller?.pop(animated: animated)
    }
    public func hide(animated: Bool = true) {
        controller?.hide(animated: animated)
    }
    public func replace<Content: MorphModalContent & View>(
        _ content: Content,
        direction: MorphDirection = .forward,
        animation: ReplaceAnimation? = .scale,
        animated: Bool = true
    ) {
        let hosting = SwiftUIModalWrapper(content, manager: self)
        hosting.applyConfig(content.modalConfig)
        controller?.replace(
            with: hosting,
            direction: direction,
            animation: animation,
            animated: animated
        )
    }
    
    /// Defer until next run-loop, then present
    @discardableResult
    public func present<Content: MorphModalContent & View>(
        _ content: Content
    ) -> PendingModal<Content> {
        PendingModal(content, manager: self, pushInsteadOfPresent: false)
    }

    /// Defer until next run-loop, then push
    @discardableResult
    public func push<Content: MorphModalContent & View>(
        _ content: Content
    ) -> PendingModal<Content> {
        PendingModal(content, manager: self, pushInsteadOfPresent: true)
    }

    fileprivate func _present<Content: MorphModalContent & View>(
        _ content: Content
    ) {
        let hosting = SwiftUIModalWrapper(content, manager: self)
        hosting.applyConfig(content.modalConfig)
        self.currentFrontModal = hosting
        controller?.present(
            hosting,
            options: content.modalConfig.options,
            sticky: content.modalConfig.sticky,
            animated: content.modalConfig.animated,
            showsOverlay: content.modalConfig.showsOverlay
        )
    }

    fileprivate func _push<Content: MorphModalContent & View>(
        _ content: Content
    ) {
        let hosting = SwiftUIModalWrapper(content, manager: self)
        hosting.applyConfig(content.modalConfig)
        self.currentFrontModal = hosting
        controller?.push(
            hosting,
            options: content.modalConfig.options,
            sticky: content.modalConfig.sticky,
            animated: content.modalConfig.animated
        )
    }
}

public protocol MorphModalContent: View {
    /// Must be `var` so builders can override
    var modalConfig: MorphModalConfiguration { get set }
}

public struct MorphModalConfiguration {
    public var options: ModalOptions     = .default
    public var sticky: StickyOption      = .none
    public var showsOverlay: Bool        = true
    public var animated: Bool            = true
    public var canDismiss: Bool          = true
    public var dismissalScrollView: UIScrollView? = nil
    public var preferredHeight: (CGFloat) -> CGFloat = {
        _ in UIScreen.main.bounds.height * 0.5
    }
    public var onWillAppear: (() -> Void)?    = nil
    public var onDidAppear:  (() -> Void)?    = nil
    public var onWillDisappear: (() -> Void)? = nil
    public var onDidDisappear: (() -> Void)?  = nil
    public init() {}
}

public struct MorphModalHost: UIViewControllerRepresentable {
    @ObservedObject var manager: MorphModalManager
    public init(manager: MorphModalManager) {
        self.manager = manager
    }
    public func makeUIViewController(context: Context) -> ModalViewController {
        let host = ModalViewController()
        host.modalPresentationStyle = .overFullScreen
        host.modalTransitionStyle   = .crossDissolve
        manager.attach(host)
        return host
    }
    public func updateUIViewController(
        _ ui: ModalViewController,
        context: Context
    ) {
    }
}

public final class SwiftUIModalWrapper: UIHostingController<AnyView>, ModalView {
    public let contentType: Any.Type
    private let contentBox: Any

    public var canDismiss: Bool = true
    public var dismissalHandlingScrollView: UIScrollView? = nil
    private var preferredHeightClosure: (CGFloat) -> CGFloat = {
        _ in UIScreen.main.bounds.height * 0.5
    }
    private var config: MorphModalConfiguration!

    public init<Content: MorphModalContent & View>(
        _ content: Content,
        manager: MorphModalManager
    ) {
        self.contentType = Content.self
        self.contentBox   = content
        let anyView       = AnyView(content.environmentObject(manager))
        super.init(rootView: anyView)
        view.backgroundColor = .clear
    }
    @objc required dynamic public init?(coder aDecoder: NSCoder) {
        fatalError()
    }

    public func applyConfig(_ cfg: MorphModalConfiguration) {
        config = cfg
        canDismiss = cfg.canDismiss
        dismissalHandlingScrollView = cfg.dismissalScrollView
        preferredHeightClosure = cfg.preferredHeight
    }
    public func preferredHeight(for width: CGFloat) -> CGFloat {
        preferredHeightClosure(width)
    }
    public func modalWillAppear() { config.onWillAppear?() }
    public func modalDidAppear() { config.onDidAppear?() }
    public func modalWillDisappear() { config.onWillDisappear?() }
    public func modalDidDisappear() { config.onDidDisappear?() }

    /// If you really need it, you can cast back:
    public var boxedContent: Any { contentBox }
}

public class SwiftUIStickyContainer<StickyView: View & DefaultConstructible>
: StickyElementsContainer
{
    private let host: UIHostingController<AnyView>

    public required init(modalVC: ModalViewController) {
        guard let mgr = modalVC.swiftModalManager else { fatalError() }
        let sv = StickyView().environmentObject(mgr)
        host = UIHostingController(rootView: AnyView(sv))

        super.init(modalVC: modalVC)

        modalVC.addChild(host)
        addSubview(host.view)
        host.view.backgroundColor = .clear
        host.didMove(toParent: modalVC)

        host.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            host.view.leadingAnchor 
                .constraint(equalTo: safeArea.leadingAnchor),
            host.view.trailingAnchor
                .constraint(equalTo: safeArea.trailingAnchor),
            host.view.topAnchor.constraint(equalTo: safeArea.topAnchor),
        ])
    }

    @available(*, unavailable) required init?(coder: NSCoder) { fatalError() }

    public override func contextDidChange(
        to newOwner: ModalView, from oldOwner: ModalView?, animated: Bool
    ) {
        modalVC.swiftModalManager?.currentFrontModal = newOwner
    }
}

private var _swiftModalManagerKey: UInt8 = 0
extension ModalViewController {
    fileprivate var swiftModalManager: MorphModalManager? {
        get {
            objc_getAssociatedObject(
                self,
                &_swiftModalManagerKey
            ) as? MorphModalManager
        }
        set {
            objc_setAssociatedObject(
                self,
                &_swiftModalManagerKey,
                newValue,
                .OBJC_ASSOCIATION_ASSIGN
            )
        }
    }
}
