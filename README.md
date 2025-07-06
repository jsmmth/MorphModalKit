<p align="center">
  <img width="100%" src="./banner.png" alt="MorphModalKit">
</p>

## Getting Started
MorphModalKit is distributed as a Swift package. There are ****two**** easy ways to add it to your project:

### 1. Swift Package Manager

1. In ****Xcode**** choose ****File › Add Packages…****
2. Paste the repository URL: ```https://github.com/jsmmth/MorphModalKit.git```
3. Press **Add Package**
4. Pick the Xcode targets that should link against **MorphModalKit** and finish.

### 2. Directly in **Package.swift**
If you manage dependencies with a manifest, add MorphModalKit to `dependencies` and link it from your target:
```swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MyApp",
    platforms: [ .iOS(.v15) ],
    dependencies: [
        // ▼ Add the package URL and the minimum version you want
        .package(url: "https://github.com/jsmmth/MorphModalKit.git", from: "main")
    ],
    targets: [
        .target(
            name: "MyApp",
            dependencies: [
                // ▼ Link the product that the package exports
                .product(name: "MorphModalKit", package: "MorphModalKit")
            ])
    ]
)
```

Once the package resolves you can import the module anywhere inside your UIKit codebase:
```swift
import MorphModalKit
```
From here you’re ready to `presentModal(…)` — see below for the full API overview.

## Presenting

You can call this from any `UIViewController`.

```swift
presentModal(ModalView, animated: Bool = true, showsOverlay: Bool = true)
```
---
>****Tip:**** The present call has an optional `sticky` param which allows you to pass `StickyElementsContainer`  which overlays and survives every *_replace_* operation (a.k.a. morph). Helpful for creating sticky elements across morphs.

  ```swift
presentModal(ModalView(), sticky: StickyElementsContainer.Type?)
```

## Modal View

When making a modal view you should conform your `UIViewController` to `ModalView`

```swift

protocol ModalView: UIViewController {
    func preferredHeight(for width: CGFloat) -> CGFloat  // Preferred Sizing
    var  canDismiss: Bool { get }  // Dismissable
    var  dismissalHandlingScrollView: UIScrollView? { get }  // Nested scroll view for dismissal

    // life‑cycle (all optional)
    func modalWillAppear()
    func modalDidAppear()
    func modalWillDisappear()
    func modalDidDisappear()
}

```
  

### Quick implementation example

```swift

class ExampleModal: UIViewController, ModalView {

    override func viewDidLoad() {
        super.viewDidLoad()
        // build your UI here
    }

    func preferredHeight(for _: CGFloat) -> CGFloat { 320 }
}

```

> ****Tip:**** The `preferredHeight` can never extend the device height. It'll animate smoothly to fit within the screen. Helpful for large modals with keyboard presenting views.

> ****Tip:**** Return `dismissalHandlingScrollView` when your modal contains a nested `UIScrollView` (or subclass) whose *_top‑bounce_* should trigger dismissal instead of overscroll.


## Navigation

### Pushing
Pushing to the modalVC allows you to create a navigation stack. The previous card stays visible behind the new one.
  
```swift

modalVC.push(ModalView())

```
You're also able to provide `StickyElementsContainer` to the push.
```swift
modalVC.push(ModalView(), sticky: StickyElements.self)
```

>****Tip:**** I find it helpful to have an extension which makes it easier to find the root ModalViewController.
```swift
import UIKit
import MorphModalKit

extension UIViewController {
   var modalVC: ModalViewController? {
       sequence(first: parent) { $0?.parent }.first { $0 is  ModalViewController } as? ModalViewController
   }
}
```

  

### Poppping/Hiding

```swift
modalVC.pop() // back to the previous card
modalVC.hide() // close the entire stack
```

Both methods respect ****spring physics**** from `modalVC.animation`.

---


### Replace (Morph)

Morph is half push, half pop — the card stays in place, its *_content_* changes.

  

```swift

modalVC.replace(
   with: ModalView(),
   direction: .forward,  // or `.backward`
   animation: .scale)  // or `.slide(px)`

```


|`ReplaceAnimation`| Visual |
|--|--|
|`.scale` *_(default)_* | New view fades while scaling to 100 % |
| `.slide(±px)` | Both views slide horizontally by `px` points |


## StickyElementsContainer

The `StickyElementsContainer` is built to support sticky elements which stay visible when replacing (morphing) content of a container. Helpful if you want a sticky back button or next button on the view and just have the content changing behind it.

When making a `StickyElementsContainer` it should conform to the UIView and when the ModalView gets replaced you'll receive a `contextDidChange` which you can override in your view to make contextual decisions or actions.

### Quick implementation example

```swift
class StickyElements: StickyElementsContainer {
    private  weak  var current: ModalView?

    required init(modalVC: ModalViewController) {
        super.init(modalVC: modalVC)
        // Layout views
    }

    required init?(coder: NSCoder) { fatalError() }
    
    // Called when ever content is replaced
    override func contextDidChange(to newOwner: ModalView, from oldOwner: ModalView?, animated: Bool) {
        // Could to some contextual animation or content change based on view
    }
}
```

You'll then need to attach the StickyElements when you `push` or `present` with `modalVC.push(ModalView(), sticky: StickyElements.self)`

> ****Important:**** `StickyElementsContainer` already forwards touches ****through**** itself, but not through its interactive sub‑views. It also has access to `modalVC` from within the view.

## Configuration

|Property|Effect|Default|
|--|--|--|
|`horizontalInset`|Side margins of every card|`10`|
|`stackVerticalSpacing`| Gap between stacked cards|`20`|
|`bottomSpacing`| Space from the bottom of the screen|`nil (safeAreaBottom + 10)`|
|`keyboardSpacing`| Space between the modal and the keyboard|`10`|
|`cornerRadius`| Card corner radius|`32`|
|`cornerMask`| Card cornerMask settings|`[.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner]`|
|`maxVisibleStack`|Max amount of cards to be shown in a stack|`2`|
|`dimBackgroundColor`|Background color of the dimmed view|`.black`|
|`dimOpacityMultiplier`|Darkness of background cards|`0.06`|
|`overlayOpacity`|Overlay opacity|`0.2`|
|`overlayColor`|Color of the overlay|`.black`|
|`modalBackgroundColor`|Background of the base modal container|`.systemBackground`|
|`animation`|Allows you to adjust modal animation spring settings|`ModalAnimationSettings(duration: 0.4, damping: 0.86, velocity: 0.8)`|
|`morphAnimation`|Allows you to adjust animation spring settings for morph animations|`ModalAnimationSettings(duration: 0.4, damping: 0.95, velocity: 1)`|
|`cardShadow`|Allows you to adjust the shadow of modal cards|`(.black, 0.12, 9, .init(width: 0, height: 2))`|
|`usesSnapshots`|Whether or not the background stacks snapshot|`true`|
|`usesSnapshotsForMorph`|Whether or not the morphing views are snapshotted|`false`|

### Example:

  

```swift
var options: ModalOptions = ModalOptions.default
options.cornerRadius = 24
options.cardShadow.opacity = 0.25
options.overlayColor = .white
options.animation.duration = 0.25
options.stackVerticalSpacing = 16

self.presentModal(MenuModal(), options: options, sticky: StickyElements.self)
```

## Tricks

### Snapshots & Performance

`ModalViewController` converts all *_background_* cards into static snapshots to keep the render loop silky‑smooth. The live view is restored automatically when the card becomes front‑most. You can disable this with `usesSnapshots` property if you want background cards to remain active.

### Height adjusting

All `ModalView` views have a `preferredHeight` value to which it will attempt to stick to. Although if there is a situation where there is not enough room on the device it will shrink the modal to ensure there is enough space to show the content. Be mindful of this when creating modal content with inputs where the keyboard will reduce the amount of available space. You may need to wrap your content in a UIScrollView and use the `dismissalHandlingScrollView`.

### Keyboard avoidance

The host listens to `UIResponder.keyboardWillChangeFrameNotification` and re‑layouts the ****entire stack****, keeping `keyboardSpacing` points between the active card and the keyboard.

### Disabling dismissal
```swift

final class CriticalWarning: UIViewController, ModalView {
    var canDismiss: Bool { false } // modal cannot be dragged down
}

```

You can still call `modalVC.pop()` programmatically.

##  Full Example

See [`Examples/UIKitExample/UIKitExample/Modals`](./Examples/UIKitExample/UIKitExample/Modals)
for a working demo that includes:

* ****MenuModal**** → pushes multiple cards.

* ****MorphPage**** → shows morph navigation with sticky header.

* ****ScrollPage**** → demonstrates scroll‑to‑dismiss.

* ****InputPage****  → automatic resizing above the keyboard.

  

---
  

### Happy morphing 🚀
