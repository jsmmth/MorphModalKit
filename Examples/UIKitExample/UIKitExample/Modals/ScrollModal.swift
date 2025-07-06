//
//  ScrollModal.swift
//  UIKitExample
//
//  Created by Joseph Smith on 05/07/2025.
//

import UIKit
import MorphModalKit

class ScrollModal: UIViewController, ModalView {
    var dismissalHandlingScrollView: UIScrollView? { textView } // Enables pulling scrollView to trigger drag of modal
    private let text = UILabel()
    
    private let textView: UITextView = {
        let tv = UITextView()
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.isEditable = false
        tv.isSelectable = false
        tv.alwaysBounceVertical = true
        tv.showsVerticalScrollIndicator = false
        tv.textContainerInset = .init(top: 32, left: 20, bottom: 32, right: 20)
        tv.font = .rounded(ofSize: 17, weight: .medium)
        tv.backgroundColor = .secondarySystemGroupedBackground
        tv.textColor = .label
        return tv
    }()

    override func viewDidLoad() {
      super.viewDidLoad()
      view.addSubview(textView)
      NSLayoutConstraint.activate([
        textView.topAnchor.constraint(equalTo: view.topAnchor),
        textView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        textView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
        textView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      ])
      textView.text = loremIpsum
    }
    
    func preferredHeight(for _: CGFloat) -> CGFloat { 800 } // It can't go beyond device height
    
    let loremIpsum = """
       Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nullam consectetur sem aliquet volutpat semper. Praesent consequat purus a libero sollicitudin egestas. Proin justo nunc, blandit eu ligula vitae, tempus mattis eros. Aliquam laoreet odio in eros rutrum varius. Sed aliquet laoreet rutrum. Nulla euismod augue eget nisl vulputate, vitae ultricies leo sagittis. Maecenas tincidunt nibh at ex tincidunt, pharetra eleifend ante luctus. Pellentesque habitant morbi tristique senectus et netus et malesuada fames ac turpis egestas. Aenean egestas orci nec sapien iaculis, in hendrerit ex hendrerit. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia curae;
       
       Nam malesuada quam at luctus varius. Ut tincidunt erat nisi, at euismod elit semper et. Aliquam eget ligula cursus, auctor ligula nec, mollis metus. Nullam iaculis, diam sit amet sodales molestie, neque orci scelerisque ligula, convallis finibus lectus nunc nec urna. Nullam sed suscipit leo. Proin mi mauris, maximus sollicitudin finibus sit amet, ornare eu diam. Integer lacinia nibh vel pharetra efficitur.

       Maecenas eget augue at felis iaculis aliquet. Aliquam et bibendum ex, pulvinar auctor neque. Aliquam fermentum sagittis eleifend. Integer consequat tincidunt elementum. Cras non fermentum dolor, et dictum neque. Pellentesque id enim tincidunt, tincidunt nunc pretium, posuere metus. In ac porttitor metus. Aenean aliquet lectus sed enim dignissim interdum. In vehicula, diam a efficitur suscipit, nisi arcu consectetur nisl, ut lobortis nisi massa non massa. Lorem ipsum dolor sit amet, consectetur adipiscing elit. Vivamus sagittis ligula ut consequat dignissim. Sed justo odio, dictum id hendrerit nec, dapibus a ante. Fusce laoreet sed nisl et condimentum. Donec posuere neque quis metus scelerisque bibendum.
       """
}
