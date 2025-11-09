import SwiftUI
import MorphModalKit

/// Example of a scrollView representable that can be used to capture the scroll position for pulling down
//struct ScrollViewRepresentable<Content: View>: UIViewRepresentable {
//  let content: Content
//  @Binding var scrollView: UIScrollView?
//
//  func makeUIView(context: Context) -> UIScrollView {
//    let scroll = UIScrollView()
//    scroll.alwaysBounceVertical = true
//    scroll.contentInsetAdjustmentBehavior = .never
//
//    let host = UIHostingController(rootView: content)
//    host.view.backgroundColor = .clear
//    host.view.translatesAutoresizingMaskIntoConstraints = false
//
//    scroll.addSubview(host.view)
//    NSLayoutConstraint.activate([
//      host.view.leadingAnchor.constraint(equalTo: scroll.contentLayoutGuide.leadingAnchor),
//      host.view.trailingAnchor.constraint(equalTo: scroll.contentLayoutGuide.trailingAnchor),
//      host.view.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor),
//      host.view.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor),
//      host.view.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor),
//    ])
//
//    // once the UIScrollView is live, hand it back
//    DispatchQueue.main.async { scrollView = scroll }
//    return scroll
//  }
//
//  func updateUIView(_ uiView: UIScrollView, context: Context) { }
//}

/// We'll use a UITextView subclass of UIScrollView for this example
struct TextViewRepresentable: UIViewRepresentable {
    let text: String
    @Binding var scrollView: UIScrollView?
    
    func makeUIView(context: Context) -> UITextView {
        let tv = UITextView()
        tv.isEditable = false
        tv.isSelectable = false
        tv.alwaysBounceVertical = true
        tv.showsVerticalScrollIndicator = false
        tv.backgroundColor = .secondarySystemGroupedBackground
        tv.textColor = .label
        tv.font = .rounded(ofSize: 17, weight: .medium)
        tv.textContainerInset = .init(top: 32, left: 20, bottom: 32, right: 20)
        tv.text = text
        tv.backgroundColor = .clear
        DispatchQueue.main.async { scrollView = tv }
        return tv
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        // nothing
    }
}

struct ScrollModal: View, MorphModalContent {
    @EnvironmentObject var modalManager: MorphModalManager
    @State private var uiScroll: UIScrollView?
    
    @State private var configStorage: MorphModalConfiguration = {
        var c = MorphModalConfiguration()
        c.canDismiss = true
        c.preferredHeight = { _ in 800 }
        return c
    }()
    var modalConfig: MorphModalConfiguration {
        get { configStorage }
        set { configStorage = newValue }
    }

    var body: some View {
        TextViewRepresentable(text: loremIpsum, scrollView: $uiScroll)
            .onChange(of: uiScroll) {
                guard let sv = uiScroll,
                      let wrapper = modalManager.currentFrontModal as? SwiftUIModalWrapper
                else { return }
                wrapper.dismissalHandlingScrollView = sv
                modalManager.refreshScrollBinding()
            }
    }

    let loremIpsum = """
       Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nullam consectetur sem aliquet volutpat semper. Praesent consequat purus a libero sollicitudin egestas. Proin justo nunc, blandit eu ligula vitae, tempus mattis eros. Aliquam laoreet odio in eros rutrum varius. Sed aliquet laoreet rutrum. Nulla euismod augue eget nisl vulputate, vitae ultricies leo sagittis. Maecenas tincidunt nibh at ex tincidunt, pharetra eleifend ante luctus. Pellentesque habitant morbi tristique senectus et netus et malesuada fames ac turpis egestas. Aenean egestas orci nec sapien iaculis, in hendrerit ex hendrerit. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia curae;
       
       Nam malesuada quam at luctus varius. Ut tincidunt erat nisi, at euismod elit semper et. Aliquam eget ligula cursus, auctor ligula nec, mollis metus. Nullam iaculis, diam sit amet sodales molestie, neque orci scelerisque ligula, convallis finibus lectus nunc nec urna. Nullam sed suscipit leo. Proin mi mauris, maximus sollicitudin finibus sit amet, ornare eu diam. Integer lacinia nibh vel pharetra efficitur.

       Maecenas eget augue at felis iaculis aliquet. Aliquam et bibendum ex, pulvinar auctor neque. Aliquam fermentum sagittis eleifend. Integer consequat tincidunt elementum. Cras non fermentum dolor, et dictum neque. Pellentesque id enim tincidunt, tincidunt nunc pretium, posuere metus. In ac porttitor metus. Aenean aliquet lectus sed enim dignissim interdum. In vehicula, diam a efficitur suscipit, nisi arcu consectetur nisl, ut lobortis nisi massa non massa. Lorem ipsum dolor sit amet, consectetur adipiscing elit. Vivamus sagittis ligula ut consequat dignissim. Sed justo odio, dictum id hendrerit nec, dapibus a ante. Fusce laoreet sed nisl et condimentum. Donec posuere neque quis metus scelerisque bibendum.
       """
}
