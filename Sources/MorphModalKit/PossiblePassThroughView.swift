import UIKit

final class PossiblePassThroughView: UIView {
    weak var modalVC: ModalViewController?

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard let modalVC = modalVC else {
            return super.hitTest(point, with: event)
        }

        if modalVC.passThroughTouches {
            for container in modalVC.containerStack.reversed() {
                let convertedPoint = convert(point, to: container.wrapper)
                if container.wrapper.bounds.contains(convertedPoint) {
                    // Touch is on a modal, handle it normally
                    if let hitView = container.wrapper.hitTest(
                        convertedPoint,
                        with: event
                    ) {
                        return hitView
                    }
                }
            }
            return nil
        }

        return super.hitTest(point, with: event)
    }
}
