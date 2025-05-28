//
//  HostSignUpView.swift
//  FaceInn
//
//  Created by CHOI on 5/25/25.
//

import UIKit

final class HostSignUpView: UIView {

    let emailTextField = UITextField()
    let emailCheckButton = UIButton(type: .system)

    let passwordTextField = UITextField()
    let passwordToggleButton = UIButton(type: .system)

    let confirmPasswordTextField = UITextField()
    let confirmPasswordToggleButton = UIButton(type: .system)

    // 비밀번호 불일치 경고 라벨
    let passwordMismatchLabel = UILabel()

    let nameTextField = UITextField()
    let phoneTextField = UITextField()

    let businessNumberTextField = UITextField()
    let verifyBusinessNumberButton = UIButton(type: .system)
    let businessNumberStatusLabel = UILabel()

    // 회원가입 버튼
    let nextButton = UIButton(type: .system)

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        // 각 텍스트필드에 키보드 완료 버튼 추가
        addDoneButtonToKeyboard(for: emailTextField)
        addDoneButtonToKeyboard(for: passwordTextField)
        addDoneButtonToKeyboard(for: confirmPasswordTextField)
        addDoneButtonToKeyboard(for: nameTextField)
        addDoneButtonToKeyboard(for: phoneTextField)
        addDoneButtonToKeyboard(for: businessNumberTextField)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // 텍스트필드 키보드에 완료 버튼 추가
    private func addDoneButtonToKeyboard(for textField: UITextField) {
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneButton = UIBarButtonItem(title: "완료", style: .done, target: textField, action: #selector(resignFirstResponder))
        toolbar.items = [flexSpace, doneButton]
        textField.inputAccessoryView = toolbar
    }


    private func setupUI() {
        backgroundColor = .white
        
        let themeColor = UIColor(red: 47/255, green: 175/255, blue: 83/255, alpha: 1)
        
        // 이메일 필드 및 중복확인 버튼 설정
        emailTextField.placeholder = "example@email.com"
        emailTextField.borderStyle = .roundedRect
        emailCheckButton.setTitle("중복확인", for: .normal)
        emailCheckButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        emailCheckButton.setTitleColor(themeColor, for: .normal)
        emailCheckButton.layer.cornerRadius = 6
        emailCheckButton.layer.borderWidth = 1
        emailCheckButton.layer.borderColor = themeColor.cgColor
        emailCheckButton.contentEdgeInsets = UIEdgeInsets(top: 6, left: 12, bottom: 6, right: 12)
        emailCheckButton.translatesAutoresizingMaskIntoConstraints = false

        let emailContainer = UIView()
        emailContainer.translatesAutoresizingMaskIntoConstraints = false
        emailContainer.addSubview(emailTextField)
        emailContainer.addSubview(emailCheckButton)
        emailTextField.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            emailTextField.leadingAnchor.constraint(equalTo: emailContainer.leadingAnchor),
            emailTextField.topAnchor.constraint(equalTo: emailContainer.topAnchor),
            emailTextField.bottomAnchor.constraint(equalTo: emailContainer.bottomAnchor),

            emailCheckButton.leadingAnchor.constraint(equalTo: emailTextField.trailingAnchor, constant: 8),
            emailCheckButton.trailingAnchor.constraint(equalTo: emailContainer.trailingAnchor),
            emailCheckButton.centerYAnchor.constraint(equalTo: emailTextField.centerYAnchor),
            emailCheckButton.widthAnchor.constraint(equalToConstant: 80),
            emailCheckButton.heightAnchor.constraint(equalToConstant: 36),

            emailTextField.heightAnchor.constraint(equalToConstant: 36)
        ])


        // 비밀번호 입력 필드 및 토글 버튼 설정
        passwordTextField.placeholder = "8자 이상 입력해주세요"
        passwordTextField.isSecureTextEntry = true
        passwordTextField.borderStyle = .roundedRect
        passwordToggleButton.setImage(UIImage(systemName: "eye"), for: .normal)
        passwordToggleButton.tintColor = .gray
        passwordToggleButton.frame = CGRect(x: 0, y: 0, width: 32, height: 32)
        passwordTextField.rightView = passwordToggleButton
        passwordTextField.rightViewMode = .always
        passwordTextField.font = .systemFont(ofSize: 14)

        // 비밀번호 확인 입력 필드 및 토글 버튼 설정
        confirmPasswordTextField.placeholder = "비밀번호를 다시 입력해주세요"
        confirmPasswordTextField.isSecureTextEntry = true
        confirmPasswordTextField.borderStyle = .roundedRect
        confirmPasswordToggleButton.setImage(UIImage(systemName: "eye"), for: .normal)
        confirmPasswordToggleButton.tintColor = .gray
        confirmPasswordToggleButton.frame = CGRect(x: 0, y: 0, width: 32, height: 32)
        confirmPasswordTextField.rightView = confirmPasswordToggleButton
        confirmPasswordTextField.rightViewMode = .always
        confirmPasswordTextField.font = .systemFont(ofSize: 14)

        // 비밀번호 불일치 시 표시할 라벨 설정
        passwordMismatchLabel.text = "비밀번호가 일치하지 않습니다."
        passwordMismatchLabel.textColor = .systemRed
        passwordMismatchLabel.font = .systemFont(ofSize: 13)
        passwordMismatchLabel.isHidden = true


        // 이름 입력 필드 설정
        nameTextField.placeholder = ""
        nameTextField.borderStyle = .roundedRect
        nameTextField.font = .systemFont(ofSize: 14)


        // 휴대폰번호 입력 필드 설정
        phoneTextField.placeholder = ""
        phoneTextField.borderStyle = .roundedRect
        phoneTextField.font = .systemFont(ofSize: 14)
        phoneTextField.keyboardType = .numberPad


        // 사업자등록번호 입력 필드 및 검증 버튼 설정
        businessNumberTextField.placeholder = "123-45-67890"
        businessNumberTextField.borderStyle = .roundedRect
        businessNumberTextField.font = .systemFont(ofSize: 14)
        verifyBusinessNumberButton.setTitle("검증", for: .normal)
        verifyBusinessNumberButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        verifyBusinessNumberButton.setTitleColor(themeColor, for: .normal)
        verifyBusinessNumberButton.layer.cornerRadius = 6
        verifyBusinessNumberButton.layer.borderWidth = 1
        verifyBusinessNumberButton.layer.borderColor = themeColor.cgColor
        verifyBusinessNumberButton.contentEdgeInsets = UIEdgeInsets(top: 6, left: 12, bottom: 6, right: 12)
        verifyBusinessNumberButton.translatesAutoresizingMaskIntoConstraints = false

        let businessContainer = UIView()
        businessContainer.translatesAutoresizingMaskIntoConstraints = false
        businessContainer.addSubview(businessNumberTextField)
        businessContainer.addSubview(verifyBusinessNumberButton)
        businessNumberTextField.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            businessNumberTextField.leadingAnchor.constraint(equalTo: businessContainer.leadingAnchor),
            businessNumberTextField.topAnchor.constraint(equalTo: businessContainer.topAnchor),
            businessNumberTextField.bottomAnchor.constraint(equalTo: businessContainer.bottomAnchor),

            verifyBusinessNumberButton.leadingAnchor.constraint(equalTo: businessNumberTextField.trailingAnchor, constant: 8),
            verifyBusinessNumberButton.trailingAnchor.constraint(equalTo: businessContainer.trailingAnchor),
            verifyBusinessNumberButton.centerYAnchor.constraint(equalTo: businessNumberTextField.centerYAnchor),
            verifyBusinessNumberButton.widthAnchor.constraint(equalToConstant: 60),
            verifyBusinessNumberButton.heightAnchor.constraint(equalToConstant: 36),

            businessNumberTextField.heightAnchor.constraint(equalToConstant: 36)
        ])

        // 사업자등록번호 상태 표시 라벨 설정
        businessNumberStatusLabel.font = .systemFont(ofSize: 13)
        businessNumberStatusLabel.textColor = .gray
        businessNumberStatusLabel.numberOfLines = 0


        // 회원가입 버튼 설정
        nextButton.setTitle("회원가입", for: .normal)
        nextButton.setTitleColor(.white, for: .normal)
        nextButton.backgroundColor = themeColor
        nextButton.layer.cornerRadius = 8
        nextButton.isEnabled = false
        nextButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        nextButton.translatesAutoresizingMaskIntoConstraints = false
        nextButton.heightAnchor.constraint(equalToConstant: 48).isActive = true


        let stackView = UIStackView(arrangedSubviews: [
            wrapWithLabel("이메일", content: emailContainer),
            wrapWithLabel("비밀번호", content: passwordTextField),
            wrapWithLabel("비밀번호 확인", content: confirmPasswordTextField),
            passwordMismatchLabel,
            wrapWithLabel("이름 (대표자명)", content: nameTextField),
            wrapWithLabel("휴대폰번호", content: phoneTextField),
            wrapWithLabel("사업자등록번호", content: businessContainer),
            businessNumberStatusLabel
        ])

        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.translatesAutoresizingMaskIntoConstraints = false

        addSubview(stackView)
        addSubview(nextButton)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 24),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 24),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -24),

            nextButton.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -24),
            nextButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 24),
            nextButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -24),
            nextButton.heightAnchor.constraint(equalToConstant: 48)
        ])
    }

    private func wrapWithLabel(_ title: String, content: UIView) -> UIStackView {
        let label = UILabel()
        label.text = title
        label.font = .systemFont(ofSize: 14, weight: .medium)
        let stack = UIStackView(arrangedSubviews: [label, content])
        stack.axis = .vertical
        stack.spacing = 6
        return stack
    }
}
