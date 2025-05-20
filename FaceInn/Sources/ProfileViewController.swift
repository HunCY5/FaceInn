//
//  ProfileViewController.swift
//  FaceInn
//
//  Created by 신찬솔 on 5/18/25.
//

import UIKit
import FirebaseFirestore
import FirebaseAuth

final class ProfileViewController: UIViewController {

    private let profileView = ProfileView()

    override func loadView() {
        view = profileView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "프로필"
        view.backgroundColor = .white
        profileView.loginButton.addTarget(self, action: #selector(didTapLogin), for: .touchUpInside)
        profileView.logoutButton.addTarget(self, action: #selector(didTapLogout), for: .touchUpInside)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        updateLoginUI()
    }

    private func updateLoginUI() {
        DispatchQueue.main.async {
            if let user = Auth.auth().currentUser {
                if user.isAnonymous {
                    self.profileView.loginButton.setTitle("로그인", for: .normal)
                    self.profileView.loginButton.isEnabled = true
                    self.profileView.loginButton.alpha = 1.0
                } else {
                    self.profileView.loginButton.setTitle("로그인 완료", for: .normal)
                    self.profileView.loginButton.isEnabled = false
                    self.profileView.loginButton.alpha = 0.5
                }
            } else {
                self.profileView.loginButton.setTitle("로그인", for: .normal)
                self.profileView.loginButton.isEnabled = true
                self.profileView.loginButton.alpha = 1.0
            }
        }
    }

    @objc private func didTapLogin() {
        let loginVC = LoginViewController()
        loginVC.delegate = self
        navigationController?.pushViewController(loginVC, animated: true)
    }

    @objc private func didTapLogout() {
        do {
            try Auth.auth().signOut()
            NotificationCenter.default.post(name: .AuthStateDidChange, object: nil)
            updateLoginUI()
        } catch {
            print("로그아웃 실패: \(error.localizedDescription)")
        }
    }
}

// MARK: - LoginDelegate

extension ProfileViewController: LoginDelegate {
    func didLoginSuccessfully() {
        updateLoginUI()
    }
}
