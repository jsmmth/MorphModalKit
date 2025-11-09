
# MorphModalKit in SwiftUI

This guide covers everything you need to integrate **MorphModalKit** into your SwiftUI app.

---

## 🚀 Installation

### Swift Package Manager

1. In Xcode, choose **File ▶ Add Packages…**  
2. Enter the URL:  
   ```
   https://github.com/jsmmth/MorphModalKit.git
   ```  
3. Click **Add Package**, select your target(s), and finish.

### Package.swift (alternative)

```swift
// swift-tools-version:5.9
import PackageDescription

let package = Package(
  name: "MyApp",
  platforms: [.iOS(.v15)],
  dependencies: [
    .package(url: "https://github.com/jsmmth/MorphModalKit.git", from: "0.0.1"),
  ],
  targets: [
    .target(
      name: "MyApp",
      dependencies: [
        .product(name: "MorphModalKit", package: "MorphModalKit")
      ]
    )
  ]
)
```

---

## 📦 Setup

1. **Import** in your SwiftUI root view:
   ```swift
   import SwiftUI
   import MorphModalKit
   ```
2. **Instantiate** a shared manager:
   ```swift
   @StateObject private var modalManager = MorphModalManager()
   ```
3. **Overlay** the host:
   ```swift
   ZStack {
     // Your app content...
   }
   .overlay(
     MorphModalHost(manager: modalManager)
       .ignoresSafeArea()
   )
   ```

---

## 📱 Presenting Modals

Use the builder APIs on your `MorphModalManager` to control presentation:

```swift
// Present a SwiftUI view
modalManager
  .present(MyModalView())
  .withSticky(MyStickyView.self)
  .withOptions { opts in
    opts.usesSnapshotsForMorph = true
  }

// Push onto the navigation stack
modalManager
  .push(MyOtherModal())
  .inheritSticky()  // reuse previous sticky
  .noSticky()       // disable sticky

// Pop or hide
modalManager.pop()
modalManager.hide()

// Morph (replace) the top card
modalManager.replace(
  NextModalView(),
  direction: .forward,
  animation: .slide(100)
)
```

### Builder Methods

- **`.withSticky(_ stickyView: S.Type)`**  
  Attach a new SwiftUI sticky view subclass of `DefaultConstructible`.

- **`.inheritSticky()`**  
  Reuse the sticky view from the previous modal.

- **`.noSticky()`**  
  Disable sticky elements for this modal.

- **`.withOptions { opts in ... }`**  
  Modify the underlying `ModalOptions` (inset, shadows, animation, etc). You can read the full configuration from the main README.

---

### ModalView Protocol

Your SwiftUI modal must conform to **`MorphModalContent`**:

```swift
struct MyModal: View, MorphModalContent {
  @EnvironmentObject var modalManager: MorphModalManager

  var modalConfig: MorphModalConfiguration = {
    var cfg = MorphModalConfiguration()
    cfg.canDismiss = true
    cfg.preferredHeight = { width in 300 }
    return cfg
  }()

  var body: some View {
    // Your SwiftUI content...
  }
}
```

- `modalConfig.canDismiss`: allow swipe‐down / overlay-tap  
- `modalConfig.preferredHeight`: desired card height  
- `modalConfig.dismissalScrollView`: assign a `UIScrollView` for pull‐to‐dismiss support  

---

## 📌 Sticky Elements

Define a SwiftUI sticky view:

```swift
public struct MyStickyView: View, DefaultConstructible {
  @EnvironmentObject var modalManager: MorphModalManager

  public init() {}
  public var body: some View {
    Text("Sticky Header")
      .frame(maxWidth: .infinity)
      .background(Color(.secondarySystemBackground))
  }
}
```

Attach via `.withSticky(MyStickyView.self)` on `present` or `push`.

---

## 🔄 Scroll-to-Dismiss

Wrap scrollable SwiftUI inside a `UIScrollView` representable:

```swift
struct DismissableScroll<Content: View>: UIViewRepresentable {
  let content: Content
  @Binding var scrollView: UIScrollView?

  func makeUIView(context: Context) -> UIScrollView {
    let scroll = UIScrollView()
    scroll.alwaysBounceVertical = true
    // embed SwiftUI via UIHostingController...
    DispatchQueue.main.async { scrollView = scroll }
    return scroll
  }
  func updateUIView(_ uiView: UIScrollView, context: Context) {}
}
```

In your modal view:

```swift
@State private var uiScroll: UIScrollView?

var body: some View {
  DismissableScroll(content: MyContent(), scrollView: $uiScroll)
    .onChange(of: uiScroll) { old, new in
      guard let sv = new,
            let wrapper = modalManager.currentFrontModal as? SwiftUIModalWrapper
      else { return }
      wrapper.dismissalHandlingScrollView = sv
      modalManager.refreshScrollBinding()
    }
}
```

## 🛠 Examples

- **InputModal**: adapts height when keyboard appears  
- **ScrollModal**: scrollable content with pull‐to‐dismiss  
- **MorphModal Steps**: demonstrates replace animations  

See [Examples/SwiftUIExample/Modals](./Examples/SwiftUIExample/SwiftUIExample/Modals) for a working demo using only the package’s APIs. Feel free to swap in your own UI—this example is just a starting point.

---

Happy morphing! 🚀
