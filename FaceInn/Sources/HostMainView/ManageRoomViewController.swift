//
//  ManageRoomViewController.swift
//  FaceInn
//
//  Created by CHOI on 5/28/25.
//

import UIKit
import FirebaseAuth

final class ManageRoomViewController: UIViewController{
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        // 로그아웃 버튼
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "로그아웃",
            style: .plain,
            target: self,
            action: #selector(didTapLogout)
        )
        
        
        
        let label = UILabel()
        label.text = "객실 관리 뷰"
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 24)
        label.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    @objc private func didTapLogout() {
        // Sign out from Firebase
        do {
            try Auth.auth().signOut()
        } catch {
            print("Sign out failed: \(error)")
        }
        // userdafualt 초기화
        UserDefaults.standard.set("guest", forKey: "userType")
        // 루트뷰 변경: MainTabBarController
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let sceneDelegate = windowScene.delegate as? SceneDelegate,
           let window = sceneDelegate.window {
            window.rootViewController = MainTabBarController()
            window.makeKeyAndVisible()
        }
    }
}
