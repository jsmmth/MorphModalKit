//
//  Button.swift
//  FamilyValuesExample
//
//  Created by Joseph Smith on 26/07/2025.
//

import UIKit

/// This is an example base class to extend for buttons for the scaling effect.
/// **Note:** This is just a basic example I do not recommend you using this as would want to consider other events like:
/// - Touches Moved
/// - Touches Cancelled
/// To ensure this captures all the cases a button should. This is just a quick write up for a simple task.

class Button: UIButton {
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        UIView.animate(
            withDuration: 0.1,
            delay: 0,
            options: [.allowUserInteraction, .beginFromCurrentState, .curveEaseOut],
            animations: {
                self.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
            },
            completion: nil
        )
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        UIView.animate(
            withDuration: 0.1,
            delay: 0,
            options: [.allowUserInteraction, .beginFromCurrentState, .curveEaseOut],
            animations: {
                self.transform = CGAffineTransform(scaleX: 1, y: 1)
            },
            completion: nil
        )
    }
}
