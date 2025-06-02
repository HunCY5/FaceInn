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
        let userType = UserDefaults.standard.string(forKey: "userType") ?? "guest"
        let user = Auth.auth().currentUser
        let db = Firestore.firestore()

        if userType == "host", let uid = user?.uid {
            db.collection("users").document(uid).getDocument { snapshot, error in
                guard error == nil, let data = snapshot?.data() else {
                    self.setRootViewController(MainTabBarController())
                    return
                }
                if let accommodationId = data["accommodationId"] as? String, !accommodationId.isEmpty {
                    self.setRootViewController(HostMainTabBarController())
                } else {
                    self.setRootViewController(AccommodationRegisterViewController())
                }
            }
        } else {
            self.setRootViewController(MainTabBarController())
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
