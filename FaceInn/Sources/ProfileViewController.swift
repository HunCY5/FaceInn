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
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateLoginUI()
    }

    private func updateLoginUI() {
        if Auth.auth().currentUser != nil {
            profileView.loginButton.setTitle("로그인 완료", for: .normal)
            profileView.loginButton.isEnabled = false
            profileView.loginButton.alpha = 0.5
        } else {
            profileView.loginButton.setTitle("로그인", for: .normal)
            profileView.loginButton.isEnabled = true
            profileView.loginButton.alpha = 1.0
        }
    }

    @objc private func didTapLogin() {
        let loginVC = LoginViewController()
        loginVC.delegate = self
        navigationController?.pushViewController(loginVC, animated: true)
    }
}

// MARK: - LoginDelegate

extension ProfileViewController: LoginDelegate {
    func didLoginSuccessfully() {
        updateLoginUI()
    }
}
