//
//  SceneDelegate.swift
//  FaceInn
//
//  Created by CHOI on 3/31/25.
//

import UIKit
import FirebaseAuth

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {

        guard let windowScene = scene as? UIWindowScene else { return }

        let window = UIWindow(windowScene: windowScene)
        // type: guest or host 구분하여 루트뷰 설정
        let userType = UserDefaults.standard.string(forKey: "userType") ?? "guest"
        let rootVC: UIViewController
        if userType == "host" {
            rootVC = HostMainTabBarController()
        } else {
            rootVC = MainTabBarController()
        }
        window.rootViewController = rootVC
        window.makeKeyAndVisible()
        self.window = window
    }
}
