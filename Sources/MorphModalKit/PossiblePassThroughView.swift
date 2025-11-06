import UIKit

final class PossiblePassThroughView: UIView {
    weak var modalVC: ModalViewController?
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard let modalVC = modalVC else {
            return super.hitTest(point, with: event)
        }
    
        guard modalVC.passThroughTouches else {
            return super.hitTest(point, with: event)
        }
        
        for container in modalVC.containerStack.reversed() {
            if container.wrapper.frame.contains(point) {
                return super.hitTest(point, with: event)
            }
        }

        return nil
    }
}
