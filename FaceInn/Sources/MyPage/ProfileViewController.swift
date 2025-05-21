
//
//  ProfileViewController.swift
//  FaceInn
//
//  Created by 신찬솔 on 5/18/25.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

final class ProfileViewController: UIViewController {

    private let profileView = ProfileView()

    override func loadView() {
        view = profileView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "마이페이지"
        profileView.loginButton.addTarget(self, action: #selector(didTapLogin), for: .touchUpInside)
        profileView.faceIDLoginButton.addTarget(self, action: #selector(didTapLogin), for: .touchUpInside)
        profileView.logoutButton.addTarget(self, action: #selector(didTapLogout), for: .touchUpInside)
        updateView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateView()
    }

    // 로그인 상태에 따라 UI 업데이트
    private func updateView() {
        if let user = Auth.auth().currentUser {
            profileView.configureView(isLoggedIn: true)
            let db = Firestore.firestore()
            db.collection("users").document(user.uid).getDocument { snapshot, error in
                if let data = snapshot?.data() {
                    self.profileView.nameLabel.text = "\(data["name"] as? String ?? "사용자")님"
                    self.profileView.emailLabel.text = data["email"] as? String ?? user.email ?? ""
                }
            }
        } else {
            profileView.configureView(isLoggedIn: false)
        }
    }

    // 로그인 화면으로 이동
    @objc private func didTapLogin() {
        let loginVC = LoginViewController()
        navigationController?.pushViewController(loginVC, animated: true)
    }

    // 로그아웃 처리 및 UI 갱신
    @objc private func didTapLogout() {
        do {
            try Auth.auth().signOut()
            updateView()
        } catch {
            print("Logout failed: \(error.localizedDescription)")
        }
    }
}
