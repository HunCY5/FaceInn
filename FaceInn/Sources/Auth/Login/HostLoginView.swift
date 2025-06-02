//
//  HostLoginView.swift
//  FaceInn
//
//  Created by CHOI on 5/24/25.
//

import UIKit

final class HostLoginView: UIView {

    // MARK: - UI Elements

    let logoImageView: UIImageView = {
        let iv = UIImageView(image: UIImage(named: "AppLogo"))
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    let welcomeLabel: UILabel = {
        let label = UILabel()
        label.text = "숙소 호스트 로그인"
        label.font = .systemFont(ofSize: 16)
        label.textAlignment = .center
        return label
    }()

    let emailField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "이메일"
        tf.borderStyle = .roundedRect
        tf.backgroundColor = UIColor.lightGray.withAlphaComponent(0.3)
        return tf
    }()

    let passwordField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "비밀번호"
        tf.borderStyle = .roundedRect
        tf.backgroundColor = UIColor.lightGray.withAlphaComponent(0.3)
        tf.isSecureTextEntry = true
        return tf
    }()

    let findIdPwButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Id/Pw 찾기", for: .normal)
        btn.setTitleColor(.systemGreen, for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 13)
        btn.contentHorizontalAlignment = .right
        return btn
    }()

    let loginButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("로그인", for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.backgroundColor = UIColor(red: 0x4F/255, green: 0xC0/255, blue: 0x6E/255, alpha: 1.0) // #4FC06E
        btn.layer.cornerRadius = 8
        btn.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        return btn
    }()

    let signupButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("회원가입", for: .normal)
        btn.setTitleColor(.systemGreen, for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 15)
        return btn
    }()

    // MARK: - Initializer

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .white
        setupLayout()
        addDoneButtonToKeyboard(for: emailField)
        addDoneButtonToKeyboard(for: passwordField)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Layout

    private func setupLayout() {
        [logoImageView, welcomeLabel,
         emailField, passwordField, findIdPwButton,
         loginButton, signupButton].forEach {
            addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        NSLayoutConstraint.activate([
            logoImageView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 40),
            logoImageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            logoImageView.widthAnchor.constraint(equalToConstant: 60),
            logoImageView.heightAnchor.constraint(equalToConstant: 60),

            welcomeLabel.topAnchor.constraint(equalTo: logoImageView.bottomAnchor, constant: 10),
            welcomeLabel.centerXAnchor.constraint(equalTo: centerXAnchor),

            emailField.topAnchor.constraint(equalTo: welcomeLabel.bottomAnchor, constant: 30),
            emailField.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 40),
            emailField.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -40),
            emailField.heightAnchor.constraint(equalToConstant: 44),

            passwordField.topAnchor.constraint(equalTo: emailField.bottomAnchor, constant: 16),
            passwordField.leadingAnchor.constraint(equalTo: emailField.leadingAnchor),
            passwordField.trailingAnchor.constraint(equalTo: emailField.trailingAnchor),
            passwordField.heightAnchor.constraint(equalToConstant: 44),

            findIdPwButton.topAnchor.constraint(equalTo: passwordField.bottomAnchor, constant: 6),
            findIdPwButton.trailingAnchor.constraint(equalTo: passwordField.trailingAnchor),

            loginButton.topAnchor.constraint(equalTo: findIdPwButton.bottomAnchor, constant: 20),
            loginButton.leadingAnchor.constraint(equalTo: emailField.leadingAnchor),
            loginButton.trailingAnchor.constraint(equalTo: emailField.trailingAnchor),
            loginButton.heightAnchor.constraint(equalToConstant: 44),

            signupButton.topAnchor.constraint(equalTo: loginButton.bottomAnchor, constant: 16),
            signupButton.centerXAnchor.constraint(equalTo: centerXAnchor),
        ])
    }
    
    private func addDoneButtonToKeyboard(for textField: UITextField) {
        let toolbar = UIToolbar(); toolbar.sizeToFit()
        let flex = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let done = UIBarButtonItem(title: "완료", style: .done, target: textField, action: #selector(resignFirstResponder))
        toolbar.items = [flex, done]
        textField.inputAccessoryView = toolbar
    }
}

