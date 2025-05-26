//
//  HostLoginViewController.swift
//  FaceInn
//
//  Created by CHOI on 5/24/25.
//

import UIKit

final class HostLoginViewController: UIViewController {

    private let hostLoginView = HostLoginView()

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
        // TODO: 로그인 처리 로직 구현
        print("호스트 로그인 버튼 눌림")
    }

    @objc private func didTapSignup() {
        let signUpVC = HostSignUpViewController()
        navigationController?.pushViewController(signUpVC, animated: true)
    }
}
