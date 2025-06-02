//
//  LoginView.swift
//  FaceInn
//
//  Created by CHOI on 5/20/25.
//

import UIKit

final class LoginView: UIView {

    // MARK: - UI Elements

    let logoImageView: UIImageView = {
        let iv = UIImageView(image: UIImage(named: "AppLogo"))
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    let welcomeLabel: UILabel = {
        let label = UILabel()
        label.text = "Welcome to FaceInn"
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

    let orLabel: UILabel = {
        let label = UILabel()
        label.text = "or"
        label.textAlignment = .center
        return label
    }()

    let leftLine = UIView()
    let rightLine = UIView()

    let appleLoginButton = makeCircleButton(systemName: "apple.logo")
    let googleLoginButton = makeCircleButton(systemName: "globe")
    let kakaoLoginButton = makeCircleButton(systemName: "message")

    static func makeCircleButton(systemName: String) -> UIButton {
        let btn = UIButton(type: .system)
        let image = UIImage(systemName: systemName)
        btn.setImage(image, for: .normal)
        btn.tintColor = .systemGreen
        btn.backgroundColor = UIColor.lightGray.withAlphaComponent(0.3)
        btn.layer.cornerRadius = 25
        btn.layer.borderWidth = 1
        btn.layer.borderColor = UIColor.systemGreen.cgColor
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }


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
         signupButton, orLabel, leftLine, rightLine,
         appleLoginButton, googleLoginButton, kakaoLoginButton
        ].forEach {
            addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        addSubview(loginButton)
        loginButton.translatesAutoresizingMaskIntoConstraints = false

        leftLine.backgroundColor = .lightGray
        rightLine.backgroundColor = .lightGray

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

            leftLine.topAnchor.constraint(equalTo: signupButton.bottomAnchor, constant: 40),
            leftLine.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 40),
            leftLine.trailingAnchor.constraint(equalTo: orLabel.leadingAnchor, constant: -8),
            leftLine.heightAnchor.constraint(equalToConstant: 1),

            orLabel.centerYAnchor.constraint(equalTo: leftLine.centerYAnchor),
            orLabel.centerXAnchor.constraint(equalTo: centerXAnchor),

            rightLine.topAnchor.constraint(equalTo: leftLine.topAnchor),
            rightLine.leadingAnchor.constraint(equalTo: orLabel.trailingAnchor, constant: 8),
            rightLine.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -40),
            rightLine.heightAnchor.constraint(equalTo: leftLine.heightAnchor),

            appleLoginButton.topAnchor.constraint(equalTo: leftLine.bottomAnchor, constant: 24),
            appleLoginButton.centerXAnchor.constraint(equalTo: centerXAnchor, constant: -80),
            appleLoginButton.widthAnchor.constraint(equalToConstant: 50),
            appleLoginButton.heightAnchor.constraint(equalToConstant: 50),

            googleLoginButton.centerYAnchor.constraint(equalTo: appleLoginButton.centerYAnchor),
            googleLoginButton.centerXAnchor.constraint(equalTo: centerXAnchor),
            googleLoginButton.widthAnchor.constraint(equalTo: appleLoginButton.widthAnchor),
            googleLoginButton.heightAnchor.constraint(equalTo: appleLoginButton.heightAnchor),

            kakaoLoginButton.centerYAnchor.constraint(equalTo: appleLoginButton.centerYAnchor),
            kakaoLoginButton.centerXAnchor.constraint(equalTo: centerXAnchor, constant: 80),
            kakaoLoginButton.widthAnchor.constraint(equalTo: appleLoginButton.widthAnchor),
            kakaoLoginButton.heightAnchor.constraint(equalTo: appleLoginButton.heightAnchor)
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
