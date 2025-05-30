//
//  HostLoginViewController.swift
//  FaceInn
//
//  Created by CHOI on 5/24/25.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

final class HostLoginViewController: UIViewController {

    private let hostLoginView = HostLoginView()
    private let loginModel = LoginModel()

    override func loadView() {
        self.view = hostLoginView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "호스트 로그인"
        view.backgroundColor = .white

        hostLoginView.loginButton.addTarget(self, action: #selector(didTapLogin), for: .touchUpInside)
        hostLoginView.signupButton.addTarget(self, action: #selector(didTapSignup), for: .touchUpInside)
    }

    @objc private func didTapLogin() {
        guard let email = hostLoginView.emailField.text,
              let password = hostLoginView.passwordField.text else { return }
        
        loginModel.login(email: email, password: password, expectedType: "host") { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(_):
                    // UserDefaults에 호스트 타입 저장
                    UserDefaults.standard.set("host", forKey: "userType")
                    
                    guard let user = Auth.auth().currentUser else { return }
                    Firestore.firestore().collection("users").document(user.uid).getDocument { snapshot, error in
                        if let document = snapshot, document.exists {
                            let data = document.data()
                            let accommodationId = data?["accommodationId"] as? String ?? ""
                            DispatchQueue.main.async {
                                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                                   let sceneDelegate = windowScene.delegate as? SceneDelegate,
                                   let window = sceneDelegate.window {
                                    if accommodationId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                        window.rootViewController = UINavigationController(rootViewController: AccommodationRegisterViewController())
                                    } else {
                                        window.rootViewController = HostMainTabBarController()
                                    }
                                    window.makeKeyAndVisible()
                                }
                            }
                        }
                    }

                case .failure(let error):
                    try? Auth.auth().signOut()
                    self?.showAlert(title: "로그인 실패", message: error.localizedDescription)
                }
            }
        }
    }

    @objc private func didTapSignup() {
        let signUpVC = HostSignUpViewController()
        signUpVC.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(signUpVC, animated: true)
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
}

extension Notification.Name {
    static let hostDidLogin = Notification.Name("hostDidLogin")
}
