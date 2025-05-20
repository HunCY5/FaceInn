//
//  Untitled.swift
//  FaceInn
//
//  Created by CHOI on 5/20/25.
//

import UIKit

final class SignUpView: UIView {

    // MARK: - UI Components

    let nameTextField = SignUpView.makeTextField(placeholder: "이름")
    let birthdayTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "생년월일"
        tf.borderStyle = .roundedRect
        return tf
    }()

    let birthdayPicker: UIDatePicker = {
        let picker = UIDatePicker()
        picker.datePickerMode = .date
        picker.locale = Locale(identifier: "ko_KR")
        picker.preferredDatePickerStyle = .wheels
        return picker
    }()

    lazy var birthdayToolbar: UIToolbar = {
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let doneButton = UIBarButtonItem(title: "완료", style: .done, target: self, action: #selector(donePickingDate))
        toolbar.setItems([doneButton], animated: false)
        return toolbar
    }()
    let emailTextField = SignUpView.makeTextField(placeholder: "이메일", keyboardType: .emailAddress)
    let checkEmailButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("이메일 중복 확인", for: .normal)
        btn.setTitleColor(.systemBlue, for: .normal)
        return btn
    }()
    let passwordTextField = SignUpView.makeTextField(placeholder: "비밀번호", isSecure: true)
    let confirmPasswordTextField = SignUpView.makeTextField(placeholder: "비밀번호 확인", isSecure: true)
    let passwordMatchLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13)
        label.textColor = .red
        label.numberOfLines = 1
        label.textAlignment = .left
        return label
    }()
    let signUpButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("회원가입", for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.backgroundColor = .systemGreen
        btn.layer.cornerRadius = 8
        btn.isEnabled = false
        return btn
    }()
    let statusLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13)
        label.textColor = .gray
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }()

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .white
        // Set up input view and accessory for birthdayTextField
        birthdayTextField.inputView = birthdayPicker
        birthdayTextField.inputAccessoryView = birthdayToolbar
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Layout

    private func setupLayout() {
        let stack = UIStackView(arrangedSubviews: [
            nameTextField,
            birthdayTextField,
            emailTextField,
            statusLabel,
            checkEmailButton,
            passwordTextField,
            confirmPasswordTextField,
            passwordMatchLabel,
            signUpButton
        ])
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 40),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -24)
        ])

        signUpButton.heightAnchor.constraint(equalToConstant: 48).isActive = true
    }

    // MARK: - Factory

    private static func makeTextField(placeholder: String,
                                      keyboardType: UIKeyboardType = .default,
                                      isSecure: Bool = false) -> UITextField {
        let tf = UITextField()
        tf.placeholder = placeholder
        tf.borderStyle = .roundedRect
        tf.keyboardType = keyboardType
        tf.isSecureTextEntry = isSecure
        tf.autocapitalizationType = .none
        return tf
    }
    // MARK: - Birthday String
    var birthdayString: String {
        return birthdayTextField.text ?? ""
    }

    @objc private func donePickingDate() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        birthdayTextField.text = formatter.string(from: birthdayPicker.date)
        endEditing(true)
    }
    
    override func didMoveToWindow() {
        super.didMoveToWindow()
        nameTextField.becomeFirstResponder()
    }
}
