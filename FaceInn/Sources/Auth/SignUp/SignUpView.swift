//
//  Untitled.swift
//  FaceInn
//
//  Created by CHOI on 5/20/25.
//

import UIKit

final class SignUpView: UIView {
    // MARK: - UI Components
    let scrollView = UIScrollView()
    let stack = UIStackView()
    let nameTextField = SignUpView.makeTextField(placeholder: "이름")
    let birthdayTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "생년월일"
        tf.borderStyle = .roundedRect
        return tf
    }()
    let phoneTextField = SignUpView.makeTextField(placeholder: "전화번호(-없이 숫자만)", keyboardType: .numberPad)
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

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .white

        // ScrollView & StackView
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 40),
            stack.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor, constant: -24),
            stack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            stack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -48)
        ])

        [nameTextField, birthdayTextField, phoneTextField, emailTextField, statusLabel, checkEmailButton, passwordTextField, confirmPasswordTextField, passwordMatchLabel, signUpButton].forEach {
            stack.addArrangedSubview($0)
        }
        signUpButton.heightAnchor.constraint(equalToConstant: 48).isActive = true

        // birthday
        birthdayTextField.inputView = birthdayPicker
        birthdayTextField.inputAccessoryView = birthdayToolbar

        // 모든 텍스트필드에 "완료" 버튼
        addDoneButtonToKeyboard(for: nameTextField)
        addDoneButtonToKeyboard(for: phoneTextField)
        addDoneButtonToKeyboard(for: emailTextField)
        addDoneButtonToKeyboard(for: passwordTextField)
        addDoneButtonToKeyboard(for: confirmPasswordTextField)

        // 키보드 올라올 때 처리
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Factory

    private static func makeTextField(placeholder: String, keyboardType: UIKeyboardType = .default, isSecure: Bool = false) -> UITextField {
        let tf = UITextField()
        tf.placeholder = placeholder
        tf.borderStyle = .roundedRect
        tf.keyboardType = keyboardType
        tf.isSecureTextEntry = isSecure
        tf.autocapitalizationType = .none
        return tf
    }

    // MARK: - Keyboard "완료" 버튼
    private func addDoneButtonToKeyboard(for textField: UITextField) {
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let done = UIBarButtonItem(title: "완료", style: .done, target: self, action: #selector(doneTapped))
        toolbar.items = [done]
        textField.inputAccessoryView = toolbar
    }

    @objc private func donePickingDate() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        birthdayTextField.text = formatter.string(from: birthdayPicker.date)
        endEditing(true)
    }

    @objc private func doneTapped() {
        endEditing(true)
    }

    // MARK: - Keyboard Scroll Handling
    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        let keyboardHeight = keyboardFrame.height
        scrollView.contentInset.bottom = keyboardHeight + 16
        scrollView.verticalScrollIndicatorInsets.bottom = keyboardHeight
    }

    @objc private func keyboardWillHide(_ notification: Notification) {
        scrollView.contentInset.bottom = 0
        scrollView.verticalScrollIndicatorInsets.bottom = 0
    }
    var birthdayString: String {
        birthdayTextField.text ?? ""
    }
}
