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

@MainActor
public final class ModalViewController: UIViewController {
    public var horizontalInset: CGFloat = 10 /// Horizontal inset
    public var cornerRadius: CGFloat = 30 /// Modal corner radius
    public var stackVerticalSpacing: CGFloat = 20 /// Vertical stack spacing between stack items
    public var dimOpacityMultiplier: CGFloat = 0.06 /// Dim opacity
    public var maxVisibleStack: Int = 2 /// How many items can a stack show
    public var removesSelfWhenCleared: Bool = true /// When `true` (default) the controller detaches itself from its parent
    public var overlayColor: UIColor = .black /// Backdrop color
    public var overlayOpacity: CGFloat = 0.2 /// Overlay opacity
    public var modalBackgroundColor: UIColor = .white /// Modal background color
    public var keyboardSpacing: CGFloat = 10 /// Space between the modal and the keyboard
    public var cornerMask: CACornerMask =
        [.layerMinXMinYCorner, .layerMaxXMinYCorner,
         .layerMinXMaxYCorner, .layerMaxXMaxYCorner] // default: all corners
    public var bottomSpacing: CGFloat? = nil // nil -> auto = max(safe-area,10)
    public var animation = ModalAnimationSettings()
    /// Shadow for every modal “card”.
    /// - color:   CALayer.shadowColor
    /// - opacity: CALayer.shadowOpacity (0–1)
    /// - radius:  CALayer.shadowRadius  (blur)
    /// - offset:  CALayer.shadowOffset  (spread direction)
    public var cardShadow: (color: UIColor, opacity: Float, radius: CGFloat, offset: CGSize) =
        (.black, 0.12, 9, .init(width: 0, height: 2))

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
        sticky: StickyElementsContainer? = nil,
        animated:Bool = true,
        showsOverlay:Bool = true,
        completion:(()->Void)? = nil) {
        overlayEnabled = showsOverlay
            if containerStack.isEmpty {
                push(modal,
                    sticky: sticky,
                    animated:animated,
                    completion:completion)
                return
            }
            hide(completion: {
                self.push(modal,
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
        sticky: StickyElementsContainer? = nil,
        animated:Bool = true,
        completion:(()->Void)? = nil)
    {
        // bring overlay if this is the first card
        if overlayEnabled && containerStack.isEmpty {
            overlay.alpha = 0
            view.insertSubview(overlay, at: 0)
            overlay.frame = view.bounds
        }

        var c = makeContainer(for: modal, sticky: sticky)
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
        modal.modalWillAppear()
        animate(animated) {
            self.overlay.alpha = self.overlayEnabled ? self.overlayOpacity : 0
            self.layoutAll()
            c.wrapper.transform = .identity
            self.applyPeekTransforms(animated:true)
        } completion:{
            modal.modalDidAppear()
            completion?()
        }
    }

    /// Pops the foreground modal from the stack
    ///
    /// - Parameters:
    ///   - animated: Whether the pop should be animated. Defaults to `true`.
    ///   - completion: An optional closure to be called after presentation completes.
    public func pop(animated:Bool = true, completion:(()->Void)? = nil) {
        guard let removing = containerStack.last else { return }

        // if last card hide the view
        guard containerStack.count > 1 else {
            hide(animated:animated,completion:completion); return
        }

        let dist  = view.bounds.maxY - removing.wrapper.frame.minY + 50
        let slide = removing.wrapper.transform.translatedBy(x:0,y:dist)
        let next = containerStack[containerStack.count-2]
        removing.modalView.modalWillDisappear()
        next.modalView.modalWillAppear()
        restoreLiveView(&containerStack[containerStack.count-2])// next
        
        animate(animated) {
            removing.wrapper.transform = slide
            self.applyPeekTransforms(animated:true, excluding: removing.wrapper)
        } completion:{
            self.containerStack.removeLast()
            removing.wrapper.removeFromSuperview()
            removing.modalView.modalDidDisappear()
            next.modalView.modalDidAppear()
            self.refreshScrollDismissBinding()
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
        let snap = card.snapshotView(afterScreenUpdates: true)!
        snap.frame = card.bounds
        card.addSubview(snap)
        outgoing.view.isHidden = true
        addChild(modal)
        modal.view.translatesAutoresizingMaskIntoConstraints = false
        modal.view.alpha = 0
        card.insertSubview(modal.view, belowSubview: c.dimView)
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
        outgoing.modalWillDisappear()
        modal.modalWillAppear()
        card.layoutIfNeeded()
        
        let slideAmount = (animation == .scale) ? 0 : ( { if case let .slide(px) = animation { return px } ; return 0 }() )
        switch animation {
        case .slide:
            let dx = (direction == .forward ? 1 : -1) * slideAmount
            modal.view.transform = .init(translationX: dx, y: 0)
            snap.transform = .identity
        default:
            modal.view.transform = direction == .forward
                ? .init(scaleX: 1.10, y: 1.10)
                : .init(scaleX: 0.92, y: 0.92)
        }
    
        animate(animated) { [weak self] in
            guard let self else { return }
            self.layout(&c)
            snap.alpha = 0
            modal.view.alpha     = 1
            modal.view.transform = .identity
            switch animation {
            case .slide:
                let dxOut = (direction == .forward ? -1 : 1) * slideAmount
                modal.view.transform = .identity
                snap.transform = .init(translationX: dxOut, y: 0)
            default:
                modal.view.transform = .identity
                snap.transform = direction == .forward
                    ? .init(scaleX: 0.92, y: 0.92)
                    : .init(scaleX: 1.10, y: 1.10)
            }
            self.applyPeekTransforms(animated: true)
            self.notifyStickyOwnerChange(old: outgoing, animated: false)
        } completion: {
            snap.removeFromSuperview()
            outgoing.view.removeFromSuperview()
            outgoing.removeFromParent()
            outgoing.modalDidDisappear()
            modal.modalDidAppear()
            completion?()
        }
    }
    
    /// Hides the entire modal stack
    ///
    /// - Parameters:
    ///   - animated: Whether the pop should be animated. Defaults to `true`.
    ///   - completion: An optional closure to be called after presentation completes.
    public func hide(animated:Bool = true, completion:(()->Void)? = nil) {
        containerStack.forEach{ $0.modalView.modalWillDisappear() }
        animate(animated) {
            self.overlay.alpha = 0
            self.containerStack.forEach{
                let dist = self.view.bounds.maxY - $0.wrapper.frame.minY + 50
                $0.wrapper.transform = $0.wrapper.transform.translatedBy(x: 0, y: dist)
            }
        } completion:{
            self.interaction.bindDismissScrollView(nil)
            self.clearAll()
            completion?()
        }
    }

    // MARK: - Internals
    @MainActor
    private struct Container {
        let wrapper: UIView
        let card: UIView
        var modalView: ModalView
        var dimView = UIView()
        var snapshot: UIView? = nil
        var sticky: StickyElementsContainer
    }
    
    private var containerStack: [Container] = []
    let interaction = ModalInteractionController()
    private var kbdHeight: CGFloat = 0
    private var overlayEnabled: Bool = true
    private var keyboardHeight: CGFloat = 0

    // overlay backdrop
    private lazy var overlay: UIView = {
        let v = UIView()
        v.backgroundColor = overlayColor
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
        reservePeekSpace: Bool = true) -> CGFloat
    {
        var h = modal.preferredHeight(for: width)
        let top    = view.safeAreaInsets.top
        let bot    = bottomSpacing ?? max(view.safeAreaInsets.bottom, 10)
        let kb     = keyboardHeight > 0 ? keyboardHeight + keyboardSpacing : 0
        let peek   = reservePeekSpace
            ? stackVerticalSpacing * CGFloat(min(4, maxVisibleStack))
            : 0
        let maxH = view.bounds.height - top - bot - kb - peek
        return min(h, maxH)
    }

    private var availableWidth: CGFloat {
        view.bounds.width - horizontalInset * 2
    }
    
    /// Re-computes size/position for one container and everything it owns.
    private func layout(_ c: inout Container) {
        let width  = availableWidth
        let height = clampedHeight(for: c.modalView, width: width)
        c.wrapper.bounds.size = .init(width: width, height: height)
        let botPad = bottomSpacing ?? max(view.safeAreaInsets.bottom, 10)
        let kbReserve = keyboardHeight > 0 ? keyboardHeight + keyboardSpacing : 0
        let bottomY = view.bounds.maxY - botPad - kbReserve
        c.wrapper.center = .init(x: view.bounds.midX,
                                 y: bottomY - height / 2)
        let s = cardShadow
        c.wrapper.layer.shadowColor   = s.color.cgColor
        c.wrapper.layer.shadowOpacity = s.opacity
        c.wrapper.layer.shadowRadius  = s.radius
        c.wrapper.layer.shadowOffset  = s.offset
        c.wrapper.layer.shadowPath    = UIBezierPath(
                roundedRect: c.wrapper.bounds,
                byRoundingCorners: .allCorners,
                cornerRadii: .init(width: cornerRadius, height: cornerRadius)
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
                    let targetTop  = refTop - self.stackVerticalSpacing
                    let ty = targetTop + halfScaled - c.wrapper.center.y
                    c.wrapper.transform =
                        .init(translationX:0, y:ty).scaledBy(x:scale, y:scale)
                    c.wrapper.alpha = depth <= self.maxVisibleStack ? 1 : 0
                    c.dimView.alpha = self.dimOpacityMultiplier*CGFloat(depth)
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
        guard g.state == .ended,
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
        if let frame = n.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
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
        _ on:Bool,
        _ block:@escaping()->Void,
        completion:(()->Void)? = nil){
            guard on else {
                block()
                completion?()
                return
            }
            let s = animation
            UIView.animate(withDuration: s.duration,
                           delay: 0,
                           usingSpringWithDamping: s.damping,
                           initialSpringVelocity: s.velocity,
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
        
        guard removesSelfWhenCleared else { return }

       willMove(toParent: nil)
       view.removeFromSuperview()
       removeFromParent()
    }

    private func makeContainer(for modal: ModalView, sticky explicit: StickyElementsContainer?) -> Container {
        addChild(modal)
        
        let wrapper = UIView()
        wrapper.layer.cornerRadius = cornerRadius
        let s = cardShadow
        wrapper.layer.shadowColor   = s.color.cgColor
        wrapper.layer.shadowOpacity = s.opacity
        wrapper.layer.shadowRadius  = s.radius
        wrapper.layer.shadowOffset  = s.offset
        wrapper.layer.maskedCorners = cornerMask
        wrapper.clipsToBounds = false
        wrapper.backgroundColor = modalBackgroundColor

        // card (clips content)
        let card = UIView()
        card.layer.cornerRadius  = cornerRadius
        card.layer.maskedCorners = cornerMask
        card.clipsToBounds       = true
        wrapper.addSubview(card)
        card.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            card.leadingAnchor.constraint(equalTo: wrapper.leadingAnchor),
            card.trailingAnchor.constraint(equalTo: wrapper.trailingAnchor),
            card.topAnchor.constraint(equalTo: wrapper.topAnchor),
            card.bottomAnchor.constraint(equalTo: wrapper.bottomAnchor)
        ])
        
        // sticky elements
        let sticky = explicit ?? StickyElementsContainer()
        sticky.wrapper = wrapper
        wrapper.addSubview(sticky)
        sticky.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            sticky.leadingAnchor.constraint(equalTo: wrapper.leadingAnchor),
            sticky.trailingAnchor.constraint(equalTo: wrapper.trailingAnchor),
            sticky.topAnchor.constraint(equalTo: wrapper.topAnchor),
            sticky.bottomAnchor.constraint(equalTo: wrapper.bottomAnchor)
        ])

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
        dim.backgroundColor        = .black
        dim.alpha                  = 0
        dim.autoresizingMask       = [.flexibleWidth, .flexibleHeight]
        dim.isUserInteractionEnabled = false
        card.addSubview(dim)
        dim.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            dim.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            dim.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            dim.topAnchor.constraint(equalTo: card.topAnchor),
            dim.bottomAnchor.constraint(equalTo: card.bottomAnchor)
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
    func interactionAnimationSettings(_ _:ModalInteractionController)
           -> ModalAnimationSettings { animation }
}
