//
//  ModalInteractionController.swift
//  MorphModalKit
//
//  Created by Joseph Smith on 05/07/2025.
//

import UIKit

// MARK: - Delegate
@MainActor
protocol ModalInteractionDelegate: AnyObject {
    func interactionCanDismiss(_ ic: ModalInteractionController) -> Bool
    func interactionPrimaryContainer(_ ic: ModalInteractionController) -> UIView?
    func interactionDidDismiss(_ ic: ModalInteractionController)
    func interactionAnimationSettings(_ ic: ModalInteractionController) -> ModalAnimationSettings
}

// MARK: - Controller
@MainActor
final class ModalInteractionController: NSObject {
    
    func attach(to host: UIView, delegate: ModalInteractionDelegate) {
        hostView = host
        self.delegate = delegate
        let g = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        g.delegate = self
        host.addGestureRecognizer(g)
        sheetPan = g
    }
    
    func setGestureEnabled(_ enabled: Bool) {
        sheetPan?.isEnabled = enabled
    }

    func bindDismissScrollView(_ scroll: UIScrollView?) {
        boundScrollView = scroll      // no extra recognisers needed
    }

    // MARK: Internals
    private var scrollWasEnabled = true
    private weak var hostView: UIView?
    private weak var delegate: ModalInteractionDelegate?
    private weak var boundScrollView: UIScrollView?
    private let dismissDistance: CGFloat = 300
    private let parallaxFactor : CGFloat = 0.08
    private var startT: CGAffineTransform = .identity
    private var bgStartTransforms : [UIView : CGAffineTransform] = [:]
    private(set) var sheetPan: UIPanGestureRecognizer!
    private var spring: ModalAnimationSettings {
        delegate?.interactionAnimationSettings(self) ?? .init()
    }

    @objc private func handlePan(_ g: UIPanGestureRecognizer) {
        guard let card = delegate?.interactionPrimaryContainer(self),
              let hv   = hostView
        else { return }

        switch g.state {
        case .began:
            startT = card.transform
            bgStartTransforms =
                hv.subviews.filter { $0 !== card && $0.layer.cornerRadius > 0 }
                           .reduce(into: [:]) { $0[$1] = $1.transform }
            if let sv = boundScrollView {
                scrollWasEnabled = sv.isScrollEnabled
                sv.isScrollEnabled = false
            }
        case .changed:
            let dragY    = max(0, g.translation(in: hv).y)
            let progress = min(1, dragY / 300)
            card.transform = startT.translatedBy(x: 0, y: dragY)
            updateBackgroundTransforms(progress: progress, dragY: dragY)
        default:
            boundScrollView?.isScrollEnabled = scrollWasEnabled
            finishDrag(of: card,
                       translation: g.translation(in: hv),
                       velocity:    g.velocity(in: hv))
        }
    }

    private func finishDrag(of card: UIView,
                            translation: CGPoint,
                            velocity:    CGPoint) {
        let dismissWanted =
            (velocity.y > 600 || translation.y > 140) &&
            (delegate?.interactionCanDismiss(self) ?? true)

        guard dismissWanted else {
            UIView.animate(
                withDuration: spring.duration,
                delay:        0,
                usingSpringWithDamping:   spring.damping,
                initialSpringVelocity:    spring.velocity,
                options: [.allowUserInteraction, .beginFromCurrentState])
            {
                card.transform = self.startT
                self.restoreBackgroundTransforms()
            }
            return
        }

        delegate?.interactionDidDismiss(self)
    }
    
    private func restoreBackgroundTransforms() {
        for (v, t) in bgStartTransforms { v.transform = t }
        bgStartTransforms.removeAll()
    }

    private func updateBackgroundTransforms(progress: CGFloat, dragY: CGFloat) {
        guard let hv = hostView else { return }
        let backs = hv.subviews.filter { $0.layer.cornerRadius > 0 }.dropLast()
        guard !backs.isEmpty else { return }

        for (idx, view) in backs.enumerated() {
            let depth         = CGFloat(backs.count - idx)
            let base          = bgStartTransforms[view] ?? view.transform
            let scale0        = 1 - depth * 0.05
            let targetScale   = scale0 + (1 - scale0) * progress
            let scaleFactor   = targetScale / scale0
            let shift = dragY * parallaxFactor / depth
            var t = base
            t = t.translatedBy(x: 0, y: shift)
            t = t.scaledBy(x: scaleFactor, y: scaleFactor)
            view.transform = t
        }
    }
}

// MARK: - UIGestureRecognizerDelegate
extension ModalInteractionController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ g: UIGestureRecognizer,
                           shouldReceive touch: UITouch) -> Bool
    {
        guard g == sheetPan,
              let hv   = hostView,
              let card = delegate?.interactionPrimaryContainer(self)
        else { return true }

        return card.frame.contains(touch.location(in: hv))
    }

    func gestureRecognizerShouldBegin(_ g: UIGestureRecognizer) -> Bool {
        guard g == sheetPan,
              let hv = hostView
        else { return true }
        let v = sheetPan.velocity(in: hv)
        guard v.y > abs(v.x) else { return false }
        if let sv = boundScrollView {
            let topOffset = -sv.adjustedContentInset.top
            if sv.contentOffset.y > topOffset { return false }
        }
        return true
    }

    func gestureRecognizer(_ g: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer)
                           -> Bool
    {
        guard let sv = boundScrollView else { return false }
        return (g == sheetPan && other == sv.panGestureRecognizer) ||
               (other == sheetPan && g == sv.panGestureRecognizer)
    }
}
