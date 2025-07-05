//
//  SceneDelegate.swift
//  UIKitExample
//
//  Created by Joseph Smith on 05/07/2025.
//

import UIKit

struct KeyboardPreloader {
  private static var didPreload = false

  static func preloadIfNeeded() {
    guard !didPreload else { return }
    didPreload = true

    // A small delay ensures the window hierarchy is all in place.
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
      guard
        let window = UIApplication.shared
                        .connectedScenes
                        .compactMap({ $0 as? UIWindowScene })
                        .flatMap({ $0.windows })
                        .first(where: { $0.isKeyWindow })
      else { return }

      let dummy = UITextField(frame: .zero)
      dummy.isHidden = true
      window.addSubview(dummy)

      // This sequence will allocate and prepare the keyboard UI.
      dummy.becomeFirstResponder()
      dummy.resignFirstResponder()
      dummy.removeFromSuperview()
    }
  }
}

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        window = UIWindow(windowScene: windowScene)
        let vc = ViewController()
        window?.rootViewController = vc
        window?.makeKeyAndVisible()
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        KeyboardPreloader.preloadIfNeeded()
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }


}

