//
//  LoginViewController.swift
//  FaceInn
//
//  Created by CHOI on 5/20/25.
//

import UIKit

protocol LoginDelegate: AnyObject {
    func didLoginSuccessfully()
}

final class LoginViewController: UIViewController {

    private let loginView = LoginView()
    private let loginModel = LoginModel()
    weak var delegate: LoginDelegate?
    var onLoginSuccess: (() -> Void)?

    override func loadView() {
        view = loginView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "로그인"
        view.backgroundColor = .white
        loginView.signupButton.addTarget(self, action: #selector(didTapSignup), for: .touchUpInside)
        loginView.loginButton.addTarget(self, action: #selector(didTapLogin), for: .touchUpInside)
    }

    @objc private func didTapLogin() {
        guard let email = loginView.emailField.text,
              let password = loginView.passwordField.text,
              !email.isEmpty, !password.isEmpty else {
            showAlert(title: "오류", message: "이메일과 비밀번호를 입력해주세요.")
            return
        }

        loginModel.login(email: email, password: password) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self?.onLoginSuccess?()
                    NotificationCenter.default.post(name: .userDidLogin, object: nil)
                    self?.navigationController?.popViewController(animated: true)
                case .failure(let error):
                    self?.showAlert(title: "로그인 실패", message: error.localizedDescription)
                }
            }
        }
    }

    @objc private func didTapSignup() {
        let signupVC = SignUpViewController()
        navigationController?.pushViewController(signupVC, animated: true)
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
}

#Preview {
    LoginViewController()
}

extension Notification.Name {
    static let userDidLogin = Notification.Name("userDidLogin")
}
