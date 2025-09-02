//
//  SceneDelegate.swift
//  FaceInn
//
//  Created by CHOI on 3/31/25.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {

        guard let windowScene = scene as? UIWindowScene else { return }

        let window = UIWindow(windowScene: windowScene)
        guard let user = Auth.auth().currentUser else {
            self.setRootViewController(MainTabBarController())
            self.window = window
            return
        }
        let db = Firestore.firestore()
        db.collection("users").document(user.uid).getDocument { snapshot, error in
            if let data = snapshot?.data(), let userType = data["type"] as? String, userType == "host" {
                self.setRootViewController(HostMainTabBarController())
            } else {
                self.setRootViewController(MainTabBarController())
            }
        }
        self.window = window
        return
    }
    private func setRootViewController(_ viewController: UIViewController) {
        DispatchQueue.main.async {
            self.window?.rootViewController = viewController
            self.window?.makeKeyAndVisible()
        }
    }
}
