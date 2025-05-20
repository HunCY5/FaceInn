//
//  ViewController.swift
//  FaceInn
//
//  Created by CHOI on 3/31/25.
//

import UIKit

class ViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground

        let label = UILabel()
        label.text = "👋 Hello, UIKit!"
        label.textColor = .label
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(label)

        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])

        let loginButton = UIButton(type: .system)
        loginButton.setTitle("로그인 하러 가기", for: .normal)
        loginButton.setTitleColor(.white, for: .normal)
        loginButton.backgroundColor = .systemGreen
        loginButton.layer.cornerRadius = 10
        loginButton.translatesAutoresizingMaskIntoConstraints = false
        loginButton.addTarget(self, action: #selector(didTapLogin), for: .touchUpInside)
        view.addSubview(loginButton)

        NSLayoutConstraint.activate([
            loginButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loginButton.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 24),
            loginButton.widthAnchor.constraint(equalToConstant: 180),
            loginButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    @objc private func didTapLogin() {
        let loginVC = LoginViewController()
        navigationController?.pushViewController(loginVC, animated: true)
    }
}
