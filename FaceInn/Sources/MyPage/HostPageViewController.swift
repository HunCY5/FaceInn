//
//  HostPageViewController.swift
//  FaceInn
//
//  Created by 신찬솔 on 5/31/25.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore
import AVFoundation

final class HostPageViewController: UIViewController {

    private let hostPageView = HostPageView()

    override func loadView() {
        view = hostPageView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "마이페이지"
        
        hostPageView.logoutButton.addTarget(self, action: #selector(didTapLogout), for: .touchUpInside)
        hostPageView.editAccommodationButton.addTarget(self, action: #selector(didTapEditAccommodation), for: .touchUpInside)
        updateView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateView()
    }

    private func updateView() {
        if let user = Auth.auth().currentUser {
            hostPageView.configureView(isLoggedIn: true)
            let db = Firestore.firestore()
            db.collection("users").document(user.uid).getDocument { snapshot, error in
                if let data = snapshot?.data() {
                    self.hostPageView.nameLabel.text = "\(data["name"] as? String ?? "사용자")님"
                    self.hostPageView.emailLabel.text = data["email"] as? String ?? user.email ?? ""
        
                }
            }
        }
    }

    // 로그아웃 처리 및 UI 갱신
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
    
    @objc private func didTapEditAccommodation() {
        let editVC = EditAccommodationViewController()
        editVC.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(editVC, animated: true)
    }

}
