//
//  ModalViewController.swift
//  MorphModalKit
//
//  Created by Joseph Smith on 05/07/2025.
//

import UIKit

public enum MorphDirection { case forward, backward }

public struct ModalAnimationSettings {
    public var duration: TimeInterval = 0.4
    public var damping: CGFloat = 0.86
    public var velocity: CGFloat = 0.8
    public init(
        duration: TimeInterval = 0.4,
        damping: CGFloat = 0.86,
        velocity: CGFloat = 0.8) {
        (self.duration,self.damping,self.velocity) = (duration,damping,velocity)
    }
}

public enum ReplaceAnimation: Equatable {
    case scale
    case slide(_ points: CGFloat)
}

public enum StickyOption {
  case none
  case inherit
  case sticky(StickyElementsContainer.Type)
}

public struct ModalOptions {
    // layout
    public var horizontalInset: CGFloat = 10
    public var cornerRadius: CGFloat = 32
    public var stackVerticalSpacing: CGFloat = 20
    public var bottomSpacing: CGFloat? = nil
    public var keyboardSpacing: CGFloat = 10
    public var centerOnIpad: Bool = true
    public var centerIPadWidthMultiplier: CGFloat = 0.7

    // background dimming
    public var dimBackgroundColor: UIColor = .black
    public var dimOpacityMultiplier: CGFloat = 0.06
    public var overlayColor: UIColor = .black
    public var overlayOpacity: CGFloat = 0.2

    // appearance
    public var maxVisibleStack: Int = 2
    public var removesSelfWhenCleared: Bool = true
    public var modalBackgroundColor: UIColor = .secondarySystemGroupedBackground
    public var cornerMask: CACornerMask = [
        .layerMinXMinYCorner, .layerMaxXMinYCorner,
        .layerMinXMaxYCorner, .layerMaxXMaxYCorner
    ]
    public var showsHandle: Bool = true
    public var handleColor: UIColor = .tertiarySystemGroupedBackground

    // behavior
    public var usesSnapshots: Bool = true
    public var usesSnapshotsForMorph: Bool = false

    // animations
    public var animation: ModalAnimationSettings = .init()
    public var morphAnimation: ModalAnimationSettings = .init(duration: 0.4, damping: 0.95, velocity: 1)

    // card shadow
    public var cardShadow: (color: UIColor, opacity: Float, radius: CGFloat, offset: CGSize) =
        (.black, 0.12, 9, .init(width: 0, height: 2))

    public init() { }
    public static let `default` = ModalOptions()
}

@MainActor
public final class ModalViewController: UIViewController {
    var options: ModalOptions = ModalOptions.default

    /// Presents a new modal as the root of the stack.
    /// If there is already a stack then it hides the existing in replace of this
    ///
    /// - Parameters:
    ///   - modal: The `ModalView` to present.
    ///   - sticky: Optional sticky elements that remain visible while replacing content (morphing). Defaults to `nil`.
    ///   - animated: Whether the presentation should be animated. Defaults to `true`.
    ///   - showsOverlay: Whether a dimmed overlay should appear behind the modal. Defaults to `true`.
    ///   - dismissable: Whether the modal can be dismissed via gestures or tapping the overlay. Defaults to `true`.
    ///   - completion: An optional closure to be called after presentation completes.
    public func present(
        _ modal:ModalView,
        options: ModalOptions = ModalOptions.default,
        sticky: StickyOption = .none,
        animated: Bool = true,
        showsOverlay: Bool = true,
        dismissableFromOutsideTaps: Bool = true,
        passThroughTouches: Bool = false,
        completion:(()->Void)? = nil) {
            self.options = options
            overlayEnabled = showsOverlay
            self.passThroughTouches = passThroughTouches
            dismissFromOverlayTaps = dismissableFromOutsideTaps && !passThroughTouches
            
            overlay.isUserInteractionEnabled = dismissFromOverlayTaps
            overlay.backgroundColor = overlayEnabled ? options.overlayColor : .clear
            
            if containerStack.isEmpty {
                push(modal,
                     options: options,
                     sticky: sticky,
                     animated:animated,
                     completion:completion)
                return
            }
            
            hide(completion: {
                self.push(modal,
                          options: options,
                          sticky: sticky,
                          animated:animated,
                          completion:completion)
            })
    }

    /// Pushes a new modal to the stack.
    ///
    /// - Parameters:
    ///   - modal: The `ModalView` to push.
    ///   - sticky: Optional sticky elements that remain visible while replacing content (morphing). Defaults to `nil`.
    ///   - animated: Whether the push should be animated. Defaults to `true`.
    ///   - completion: An optional closure to be called after presentation completes.
    public func push(
        _ modal:ModalView,
        options: ModalOptions? = nil,
        sticky: StickyOption = .none,
        animated:Bool = true,
        completion:(()->Void)? = nil)
    {
        let options = options ?? self.options
        
        // bring overlay if this is the first card
        if containerStack.isEmpty, !passThroughTouches {
            overlay.alpha = 0
            view.insertSubview(overlay, at: 0)
            overlay.frame = view.bounds
        }
        
        let stickyType: StickyElementsContainer.Type?
        switch sticky {
        case .none:
          stickyType = nil
        case .sticky(let type):
          stickyType = type
        case .inherit:
          // if there’s a previous container, pull its sticky’s class
          if let prev = containerStack.last {
            stickyType = type(of: prev.sticky)
          } else {
            stickyType = nil
          }
        }

        var c = makeContainer(for: modal, sticky: stickyType)
        layout(&c)
        c.wrapper.transform = .init(
            translationX: 0,
            y: view.bounds.maxY - c.wrapper.frame.minY + 50)
        view.addSubview(c.wrapper)
        containerStack.append(c)
        updateHitTesting()
        updateSnapshots(newFront: c.wrapper)
        refreshScrollDismissBinding()
        let previous = containerStack.dropLast().last?.modalView
        notifyStickyOwnerChange(old: previous, animated: false)
        modal.modalWillAppear(fromReplace: false)
        animate(options.animation, animated) {
            self.overlay.alpha = self.options.overlayOpacity
            self.layoutAll()
            c.wrapper.transform = .identity
            self.applyPeekTransforms(animated:true)
        } completion:{
            modal.modalDidAppear(fromReplace: false)
            completion?()
        }
    }

    /// Pops the foreground modal from the stack
    ///
    /// - Parameters:
    ///   - animated: Whether the pop should be animated. Defaults to `true`.
    ///   - completion: An optional closure to be called after presentation completes.
    public func pop(animated:Bool = true, completion:(()->Void)? = nil) {
        guard !isTransitioning else { return }
        guard let removing = containerStack.last else { return }

        // if last card hide the view
        guard containerStack.count > 1 else {
            hide(animated:animated,completion:completion); return
        }
        
        isTransitioning = true
        let dist  = view.bounds.maxY - removing.wrapper.frame.minY + 50
        let slide = removing.wrapper.transform.translatedBy(x:0,y:dist)
        let next = containerStack[containerStack.count-2]
        removing.modalView.modalWillDisappear(beingReplaced: false)
        next.modalView.modalWillAppear(fromReplace: false)
        restoreLiveView(&containerStack[containerStack.count-2])// next
        
        animate(options.animation, animated) {
            removing.wrapper.transform = slide
            self.applyPeekTransforms(animated:true, excluding: removing.wrapper)
        } completion:{
            self.containerStack.removeLast()
            removing.wrapper.removeFromSuperview()
            removing.modalView.modalDidDisappear(beingReplaced: false)
            next.modalView.modalDidAppear(fromReplace: false)
            self.refreshScrollDismissBinding()
            self.isTransitioning = false
            completion?()
        }
    }
    
    /// Replaces the content with a different modal (morph)
    ///
    /// - Parameters:
    ///   - with: The `ModalView` to replace with.
    ///   - direction: The direction of the animation. Defaults to `.forward`.
    ///   - animation: The animation type of the replace. Defaults to `.scale`.
    ///   - animated: Whether the pop should be animated. Defaults to `true`.
    ///   - completion: An optional closure to be called after presentation completes.
    // MARK: Morph-replace (Menu → Morph 1, Morph 2 ↔ Morph 3, …)
    public func replace(
        with modal: ModalView,
        direction: MorphDirection = .forward,
        animation: ReplaceAnimation? = .scale,
        animated: Bool = true,
        completion: (() -> Void)? = nil)
    {
        guard var c = containerStack.last else {
            present(modal, animated: animated, completion: completion)
            return
        }
        
        let card = c.card
        let outgoing = c.modalView
        var old: UIView = outgoing.view
        if options.usesSnapshotsForMorph {
            let snap = card.snapshotView(afterScreenUpdates: true)!
            snap.frame = card.bounds
            card.addSubview(snap)
            outgoing.view.isHidden = true
            old = snap
        }
        
        addChild(modal)
        modal.view.translatesAutoresizingMaskIntoConstraints = false
        modal.view.alpha = 0
        card.addSubview(modal.view)
        NSLayoutConstraint.activate([
            modal.view.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            modal.view.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            modal.view.topAnchor.constraint(equalTo: card.topAnchor),
            modal.view.bottomAnchor.constraint(equalTo: card.bottomAnchor)
        ])
        modal.didMove(toParent: self)
        c.modalView = modal
        containerStack[containerStack.count - 1] = c
        refreshScrollDismissBinding()
        outgoing.modalWillDisappear(beingReplaced: true)
        modal.modalWillAppear(fromReplace: true)
        card.layoutIfNeeded()
        
        let slideAmount = (animation == .scale) ? 0 : ( { if case let .slide(px) = animation { return px } ; return 0 }() )
        switch animation {
        case .slide:
            let dx = (direction == .forward ? 1 : -1) * slideAmount
            modal.view.transform = .init(translationX: dx, y: 0)
            old.transform = .identity
        default:
            modal.view.transform = direction == .forward
                ? .init(scaleX: 1.05, y: 1.05)
                : .init(scaleX: 0.98, y: 0.98)
        }
    
        animate(options.morphAnimation, animated) { [weak self] in
            guard let self else { return }
            self.layout(&c)
            old.alpha = 0
            modal.view.alpha     = 1
            modal.view.transform = .identity
            switch animation {
            case .slide:
                let dxOut = (direction == .forward ? -1 : 1) * slideAmount
                modal.view.transform = .identity
                old.transform = .init(translationX: dxOut, y: 0)
            default:
                modal.view.transform = .identity
                old.transform = direction == .forward
                    ? .init(scaleX: 0.98, y: 0.98)
                    : .init(scaleX: 1.05, y: 1.05)
            }
            self.applyPeekTransforms(animated: true)
            self.notifyStickyOwnerChange(old: outgoing, animated: false)
        } completion: {
            old.removeFromSuperview()
            outgoing.view.removeFromSuperview()
            outgoing.removeFromParent()
            outgoing.modalDidDisappear(beingReplaced: true)
            modal.modalDidAppear(fromReplace: true)
            completion?()
        }
    }
    
    /// Hides the entire modal stack
    ///
    /// - Parameters:
    ///   - animated: Whether the pop should be animated. Defaults to `true`.
    ///   - completion: An optional closure to be called after presentation completes.
    public func hide(animated:Bool = true, completion:(()->Void)? = nil) {
        guard !isTransitioning else { return }
        isTransitioning = true
        containerStack.forEach{ $0.modalView.modalWillDisappear(beingReplaced: false) }
        animate(options.animation, animated) {
            self.overlay.alpha = 0
            self.containerStack.forEach{
                let dist = self.view.bounds.maxY - $0.wrapper.frame.minY + 50
                $0.wrapper.transform = $0.wrapper.transform.translatedBy(x: 0, y: dist)
            }
        } completion:{
            self.interaction.bindDismissScrollView(nil)
            self.clearAll()
            self.isTransitioning = false
            completion?()
        }
    }
    
    /// Sets the height of the top-most modal and animates the size change.
    /// - Parameters:
    ///   - height: Desired content height. Pass `nil` to return to the modal's preferred height.
    ///   - animated: Whether to animate the change.
    ///   - reservePeekSpace: If `true`, we still reserve vertical space for the peek stack (same rule as layout).
    public func setTopModalHeight(
        _ height: CGFloat?,
        animated: Bool = true,
        reservePeekSpace: Bool = true
    ) {
        guard !isTransitioning, !containerStack.isEmpty else { return }
        containerStack[containerStack.count - 1].overrideHeight = height

        animate(options.animation, animated) {
            self.layoutAll()
            self.applyPeekTransforms(animated: true)
        }
    }
    
    /// Sets the height of a specific modal
    /// - Parameters:
    ///   - for: The modal view you want to adjust the height for
    ///   - to: Desired content height. Pass `nil` to return to the modal's preferred height.
    ///   - animated: Whether to animate the change.
    public func setHeight(
        for modal: ModalView,
        to height: CGFloat?,
        animated: Bool = true
    ) {
        guard let idx = containerStack.firstIndex(where: { $0.modalView === modal }) else { return }
        containerStack[idx].overrideHeight = height
        animate(options.animation, animated) {
            self.layoutAll()
            self.applyPeekTransforms(animated: true)
        }
    }

    // MARK: - Internals
    @MainActor
    struct Container {
        let wrapper: UIView
        let card: UIView
        var modalView: ModalView
        var dimView = UIView()
        var snapshot: UIView? = nil
        var sticky: StickyElementsContainer
        var overrideHeight: CGFloat? = nil
    }
    
    private var isTransitioning: Bool = false
    private(set) var containerStack: [Container] = []
    let interaction = ModalInteractionController()
    private var kbdHeight: CGFloat = 0
    private var overlayEnabled: Bool = true
    private var keyboardHeight: CGFloat = 0
    private var dismissFromOverlayTaps: Bool = true
    private(set) var passThroughTouches: Bool = false

    // overlay backdrop
    private lazy var overlay: UIView = {
        let v = UIView()
        v.backgroundColor = options.overlayColor
        v.autoresizingMask = [.flexibleWidth,.flexibleHeight]
        return v
    }()

    // MARK: LifeCycle
    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = false
        interaction.attach(to: view, delegate: self)
        registerKeyboard()
        overlay.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(onOverlayTap)))
    }
    
    public override func loadView() {
        let v = PossiblePassThroughView()
        v.modalVC = self
        self.view = v
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        overlay.frame = view.bounds
        layoutAll()
    }

    // MARK: Layout
    private func layoutAll() {
        guard !containerStack.isEmpty else { return }
        for i in containerStack.indices {
            layout(&containerStack[i])
        }
    }
    
    private func clampedHeight(
        for modal: ModalView,
        width: CGFloat,
        reservePeekSpace: Bool = true,
        overrideHeight: CGFloat? = nil
    ) -> CGFloat {
        let requested = overrideHeight ?? modal.preferredHeight(for: width)
        let top = view.safeAreaInsets.top
        let bot = options.bottomSpacing ?? max(view.safeAreaInsets.bottom, 10)
        let kb  = keyboardHeight > 0 ? keyboardHeight + options.keyboardSpacing : 0
        let peek = reservePeekSpace ? options.stackVerticalSpacing * CGFloat(min(4, options.maxVisibleStack)) : 0
        let maxH = view.bounds.height - top - bot - kb - peek
        return min(requested, maxH)
    }

    private var availableWidth: CGFloat {
        if traitCollection.userInterfaceIdiom == .pad && options.centerOnIpad {
            return view.bounds.width * options.centerIPadWidthMultiplier
        }
        
        return view.bounds.width - options.horizontalInset * 2
    }
    
    /// Re-computes size/position for one container and everything it owns.
    private func layout(_ c: inout Container) {
        let width  = availableWidth
        let height = clampedHeight(for: c.modalView, width: width, overrideHeight: c.overrideHeight)
        c.wrapper.bounds.size = .init(width: width, height: height)
        
        let kbReserve = keyboardHeight > 0 ? keyboardHeight + options.keyboardSpacing : 0
        if traitCollection.userInterfaceIdiom == .pad && options.centerOnIpad {
            // center on iPad, but move up by half the keyboard reserve
            let centerY = view.bounds.midY - kbReserve/2
            c.wrapper.center = CGPoint(
                x: view.bounds.midX,
                y: centerY
            )
        } else {
            // bottom-anchored on phones (or if centerOnIpad = false)
            let botPad = options.bottomSpacing ?? max(view.safeAreaInsets.bottom, 10)
            let bottomY = view.bounds.maxY - botPad - kbReserve
            c.wrapper.center = CGPoint(
                x: view.bounds.midX,
                y: bottomY - height/2
            )
        }
        
        let s = options.cardShadow
        c.wrapper.layer.shadowColor   = s.color.cgColor
        c.wrapper.layer.shadowOpacity = s.opacity
        c.wrapper.layer.shadowRadius  = s.radius
        c.wrapper.layer.shadowOffset  = s.offset
        c.wrapper.layer.shadowPath    = UIBezierPath(
                roundedRect: c.wrapper.bounds,
                byRoundingCorners: .allCorners,
                cornerRadii: .init(width: options.cornerRadius, height: options.cornerRadius)
        ).cgPath
        c.wrapper.layoutIfNeeded()
    }

    private func applyPeekTransforms(
        animated:Bool,
        excluding skip:UIView? = nil) {
            guard !containerStack.isEmpty else { return }

            let work: () -> Void = {
                // real foreground (skip may still be on-screen)
                guard let front = self.containerStack.last(where:{ $0.wrapper !== skip })
                else { return }

                front.wrapper.transform = .identity
                front.wrapper.alpha     = 1
                front.dimView.alpha     = 0

                var refTop = front.wrapper.frame.minY
                var depth  = 1

                for c in self.containerStack.reversed() {
                    if c.wrapper === skip || c.wrapper === front.wrapper { continue }
                    let scale = 1 - CGFloat(depth)*0.05
                    let halfScaled = c.wrapper.bounds.height*scale/2
                    let targetTop  = refTop - self.options.stackVerticalSpacing
                    let ty = targetTop + halfScaled - c.wrapper.center.y
                    c.wrapper.transform =
                        .init(translationX:0, y:ty).scaledBy(x:scale, y:scale)
                    c.wrapper.alpha = depth <= self.options.maxVisibleStack ? 1 : 0
                    c.dimView.alpha = self.options.dimOpacityMultiplier*CGFloat(depth)
                    refTop = targetTop
                    depth += 1
                }
            }
            animated ? work() : UIView.performWithoutAnimation(work)
    }
    
    // MARK: Snapshot helpers
    /// Turns every *non-foreground* card into a static snapshot and hides the real
    /// view.  The live view is restored automatically when the card returns to the
    /// front (pop, swipe-back, …).
    private func updateSnapshots(newFront frontWrapper: UIView?) {
        guard options.usesSnapshots else { return }
        for idx in 0..<containerStack.count {
            if containerStack[idx].wrapper === frontWrapper {
                restoreLiveView(&containerStack[idx])
            } else {
                makeSnapshot(&containerStack[idx])
            }
        }
    }

    private func makeSnapshot(_ c: inout Container) {
        guard c.snapshot == nil else { return }
        let snap = c.card.snapshotView(afterScreenUpdates: false)!
        snap.frame = c.card.bounds
        c.card.insertSubview(snap, belowSubview: c.dimView)
        c.modalView.view.isHidden = true
        c.snapshot = snap
    }

    private func restoreLiveView(_ c: inout Container) {
        guard let snap = c.snapshot else { return } // already live
        snap.removeFromSuperview()
        c.snapshot = nil
        c.modalView.view.isHidden = false
    }

    // MARK: Utils
    @objc private func onOverlayTap(_ g:UITapGestureRecognizer){
        guard dismissFromOverlayTaps,
              g.state == .ended,
              containerStack.last?.modalView.canDismiss ?? true else { return }
        hide()
    }
    
    func refreshScrollDismissBinding() {
        if let sv = containerStack.last?.modalView.dismissalHandlingScrollView {
            interaction.bindDismissScrollView(sv)
        } else {
            interaction.bindDismissScrollView(nil)
        }
    }
    
    private func notifyStickyOwnerChange(old: ModalView?, animated: Bool) {
        guard let top = containerStack.last else { return }
        top.sticky.contextDidChange(to: top.modalView,
                                    from: old,
                                    animated: animated)
    }
    
    
    private func updateHitTesting() {
        // Enable touches only while there is at least one modal in the stack
        view.isUserInteractionEnabled = !containerStack.isEmpty
    }

    private func registerKeyboard(){
        let nc = NotificationCenter.default
        [UIResponder.keyboardWillShowNotification,
         UIResponder.keyboardWillChangeFrameNotification,
         UIResponder.keyboardWillHideNotification]
            .forEach { nc.addObserver(
                self,
                selector: #selector(handleKeyboard(_:)),
                name: $0,
                object: nil) }
    }
    
    @objc private func handleKeyboard(_ n: Notification) {
        if let _ = n.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
            var rawHeight: CGFloat = 0
            if let frame = n.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                rawHeight = frame.height - view.safeAreaInsets.bottom
            }
            if n.name == UIResponder.keyboardWillHideNotification {
                rawHeight = 0
            }
            keyboardHeight = max(rawHeight, 0)
        }
        let duration = (n.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double) ?? 0.25
        let curveRaw = (n.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey]   as? UInt)  ?? UInt(UIView.AnimationCurve.easeInOut.rawValue)
        let options  = UIView.AnimationOptions(rawValue: curveRaw << 16)
        UIView.animate(withDuration: duration, delay: 0, options: options) {
            self.layoutAll()
            self.applyPeekTransforms(animated: true)
        }
    }

    private func animate(
        _ animation: ModalAnimationSettings,
        _ on:Bool,
        _ block:@escaping()->Void,
        completion:(()->Void)? = nil){
            guard on else {
                block()
                completion?()
                return
            }
            UIView.animate(withDuration: animation.duration,
                           delay: 0,
                           usingSpringWithDamping: animation.damping,
                           initialSpringVelocity: animation.velocity,
                           options:[.allowUserInteraction,.beginFromCurrentState],
                           animations: block){ _ in completion?() }
    }

    private func clearAll(){
        overlay.removeFromSuperview()
        containerStack.forEach {
            $0.wrapper.removeFromSuperview()
            $0.modalView.removeFromParent()
        }
        containerStack.removeAll()
        updateHitTesting()
        
        guard options.removesSelfWhenCleared else { return }
        self.dismiss(animated: false)
    }

    private func makeContainer(for modal: ModalView, sticky explicit: StickyElementsContainer.Type?) -> Container {
        addChild(modal)
        
        let wrapper = UIView()
        wrapper.layer.cornerRadius = options.cornerRadius
        let s = options.cardShadow
        wrapper.layer.shadowColor = s.color.cgColor
        wrapper.layer.shadowOpacity = s.opacity
        wrapper.layer.shadowRadius = s.radius
        wrapper.layer.shadowOffset = s.offset
        wrapper.layer.maskedCorners = options.cornerMask
        wrapper.clipsToBounds = false
        wrapper.backgroundColor = options.modalBackgroundColor

        // card (clips content)
        let card = UIView()
        card.layer.cornerRadius = options.cornerRadius
        card.layer.maskedCorners = options.cornerMask
        card.clipsToBounds = true
        wrapper.addSubview(card)
        card.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            card.leadingAnchor.constraint(equalTo: wrapper.leadingAnchor),
            card.trailingAnchor.constraint(equalTo: wrapper.trailingAnchor),
            card.topAnchor.constraint(equalTo: wrapper.topAnchor),
            card.bottomAnchor.constraint(equalTo: wrapper.bottomAnchor)
        ])
        
        // sticky elements
        let sticky = (explicit != nil) ? explicit!.init(modalVC: self) : StickyElementsContainer(modalVC: self)
        sticky.wrapper = wrapper
        sticky.layer.cornerRadius = options.cornerRadius
        sticky.layer.maskedCorners = options.cornerMask
        sticky.clipsToBounds = true
        wrapper.addSubview(sticky)
        sticky.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            sticky.leadingAnchor.constraint(equalTo: wrapper.leadingAnchor),
            sticky.trailingAnchor.constraint(equalTo: wrapper.trailingAnchor),
            sticky.topAnchor.constraint(equalTo: wrapper.topAnchor),
            sticky.bottomAnchor.constraint(equalTo: wrapper.bottomAnchor)
        ])
        
        if options.showsHandle, modal.canDismiss {
            let handle = UIView()
            handle.backgroundColor = options.handleColor
            handle.layer.cornerCurve = .continuous
            handle.layer.cornerRadius = 2
            handle.translatesAutoresizingMaskIntoConstraints = false
            wrapper.addSubview(handle)
            NSLayoutConstraint.activate([
                handle.widthAnchor.constraint(equalToConstant: 52),
                handle.heightAnchor.constraint(equalToConstant: 4),
                handle.topAnchor.constraint(equalTo: wrapper.topAnchor, constant: 8),
                handle.centerXAnchor.constraint(equalTo: wrapper.centerXAnchor),
            ])
        }

        // live content
        modal.view.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(modal.view)
        NSLayoutConstraint.activate([
            modal.view.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            modal.view.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            modal.view.topAnchor.constraint(equalTo: card.topAnchor),
            modal.view.bottomAnchor.constraint(equalTo: card.bottomAnchor)
        ])
        modal.didMove(toParent: self)

        // dim overlay
        let dim = UIView(frame: card.bounds)
        dim.backgroundColor = options.dimBackgroundColor
        dim.alpha = 0
        dim.isUserInteractionEnabled = false
        dim.layer.cornerRadius = options.cornerRadius
        dim.layer.maskedCorners = options.cornerMask
        dim.clipsToBounds = true
        wrapper.addSubview(dim)
        dim.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            dim.leadingAnchor.constraint(equalTo: wrapper.leadingAnchor),
            dim.trailingAnchor.constraint(equalTo: wrapper.trailingAnchor),
            dim.topAnchor.constraint(equalTo: wrapper.topAnchor),
            dim.bottomAnchor.constraint(equalTo: wrapper.bottomAnchor)
        ])

        return Container(wrapper: wrapper,
                         card:    card,
                         modalView: modal,
                         dimView: dim,
                         sticky:  sticky)
    }
}

// MARK: - ModalInteractionDelegate
extension ModalViewController: ModalInteractionDelegate {
    func interactionDidDismiss(_ ic: ModalInteractionController) {
        self.pop(animated: true)
    }
    func interactionCanDismiss(_ _:ModalInteractionController) -> Bool {
        containerStack.last?.modalView.canDismiss ?? true
    }
    func interactionPrimaryContainer(_ _:ModalInteractionController) -> UIView? {
        containerStack.last?.wrapper
    }
    func interactionAnimationSettings(_ _:ModalInteractionController) -> ModalAnimationSettings {
        options.animation
    }
}
