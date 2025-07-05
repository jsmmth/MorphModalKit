//
//  UIViewController+ModalHost.swift
//  UIKitExample
//
//  Created by Joseph Smith on 05/07/2025.
//

import UIKit
import MorphModalKit

extension UIViewController {
   var modalVC: ModalViewController? {
       sequence(first: parent) { $0?.parent }.first { $0 is  ModalViewController } as? ModalViewController
   }
}
