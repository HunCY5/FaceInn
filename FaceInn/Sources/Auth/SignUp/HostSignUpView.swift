//
//  HostSignUpView.swift
//  FaceInn
//
//  Created by CHOI on 5/25/25.
//

import UIKit

final class HostSignUpView: UIView {


    let scrollView = UIScrollView()
    let contentStack = UIStackView()
    
    let emailTextField = UITextField()
    let emailCheckButton = UIButton(type: .system)
    let emailFormatLabel = UILabel()

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

    private func setupUI() {
        backgroundColor = .white
        
        // 스크롤뷰
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.alwaysBounceVertical = true
        scrollView.keyboardDismissMode = .interactive
        addSubview(scrollView)
        
        contentStack.axis = .vertical
        contentStack.spacing = 16
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)
        
        // 이메일 필드 + 버튼
        let emailContainer = UIView()
        emailContainer.translatesAutoresizingMaskIntoConstraints = false
        emailTextField.placeholder = "example@email.com"
        emailTextField.borderStyle = .roundedRect
        emailTextField.translatesAutoresizingMaskIntoConstraints = false
        
        let themeColor = UIColor(red: 47/255, green: 175/255, blue: 83/255, alpha: 1)
        emailCheckButton.setTitle("중복확인", for: .normal)
        emailCheckButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        emailCheckButton.layer.cornerRadius = 6
        emailCheckButton.layer.borderWidth = 1
        emailCheckButton.layer.borderColor = themeColor.cgColor
        emailCheckButton.setTitleColor(themeColor, for: .normal)
        emailCheckButton.contentEdgeInsets = .init(top: 6, left: 12, bottom: 6, right: 12)
        emailCheckButton.translatesAutoresizingMaskIntoConstraints = false
        
        emailContainer.addSubview(emailTextField)
        emailContainer.addSubview(emailCheckButton)
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
        emailFormatLabel.font = .systemFont(ofSize: 13)
        emailFormatLabel.textColor = .gray
        emailFormatLabel.isHidden = true
        
        // 비밀번호
        passwordTextField.placeholder = "비밀번호를 입력해주세요"
        passwordTextField.isSecureTextEntry = true
        passwordTextField.borderStyle = .roundedRect
        passwordTextField.translatesAutoresizingMaskIntoConstraints = false
        passwordToggleButton.setImage(UIImage(systemName: "eye"), for: .normal)
        passwordToggleButton.tintColor = .gray
        passwordToggleButton.frame = CGRect(x:0,y:0,width:32,height:32)
        passwordTextField.rightView = passwordToggleButton
        passwordTextField.rightViewMode = .always
        
        // 비밀번호 확인
        confirmPasswordTextField.placeholder = "비밀번호를 다시 입력해주세요"
        confirmPasswordTextField.isSecureTextEntry = true
        confirmPasswordTextField.borderStyle = .roundedRect
        confirmPasswordTextField.translatesAutoresizingMaskIntoConstraints = false
        confirmPasswordToggleButton.setImage(UIImage(systemName: "eye"), for: .normal)
        confirmPasswordToggleButton.tintColor = .gray
        confirmPasswordToggleButton.frame = CGRect(x:0,y:0,width:32,height:32)
        confirmPasswordTextField.rightView = confirmPasswordToggleButton
        confirmPasswordTextField.rightViewMode = .always
        // 비밀번호 불일치 시 표시할 라벨 설정
        
        passwordMismatchLabel.text = "비밀번호가 일치하지 않습니다."
        passwordMismatchLabel.font = .systemFont(ofSize: 13)
        passwordMismatchLabel.textColor = .systemRed
        passwordMismatchLabel.isHidden = true
        
        // 이름
        nameTextField.placeholder = "대표자명"
        nameTextField.borderStyle = .roundedRect
        nameTextField.translatesAutoresizingMaskIntoConstraints = false
        
        // 휴대폰
        phoneTextField.placeholder = "01012345678"
        phoneTextField.borderStyle = .roundedRect
        phoneTextField.keyboardType = .numberPad
        phoneTextField.translatesAutoresizingMaskIntoConstraints = false
        
        // 사업자등록번호
        let businessContainer = UIView()
        businessContainer.translatesAutoresizingMaskIntoConstraints = false
        businessNumberTextField.placeholder = "사업자등록번호 10자리 입력"
        businessNumberTextField.borderStyle = .roundedRect
        businessNumberTextField.keyboardType = .numberPad
        businessNumberTextField.translatesAutoresizingMaskIntoConstraints = false
        
        verifyBusinessNumberButton.setTitle("검증", for: .normal)
        verifyBusinessNumberButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        verifyBusinessNumberButton.layer.cornerRadius = 6
        verifyBusinessNumberButton.layer.borderWidth = 1
        verifyBusinessNumberButton.layer.borderColor = themeColor.cgColor
        verifyBusinessNumberButton.setTitleColor(themeColor, for: .normal)
        verifyBusinessNumberButton.contentEdgeInsets = .init(top:6,left:12,bottom:6,right:12)
        verifyBusinessNumberButton.translatesAutoresizingMaskIntoConstraints = false
        
        businessContainer.addSubview(businessNumberTextField)
        businessContainer.addSubview(verifyBusinessNumberButton)
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
        
        businessNumberStatusLabel.font = .systemFont(ofSize: 13)
        businessNumberStatusLabel.textColor = .gray
        businessNumberStatusLabel.numberOfLines = 0
        
        // contentStack에 차례대로 추가
        contentStack.addArrangedSubview(wrapWithLabel("이메일", content: emailContainer))
        contentStack.addArrangedSubview(emailFormatLabel)
        contentStack.addArrangedSubview(wrapWithLabel("비밀번호", content: passwordTextField))
        contentStack.addArrangedSubview(wrapWithLabel("비밀번호 확인", content: confirmPasswordTextField))
        contentStack.addArrangedSubview(passwordMismatchLabel)
        contentStack.addArrangedSubview(wrapWithLabel("이름 (대표자명)", content: nameTextField))
        contentStack.addArrangedSubview(wrapWithLabel("휴대폰번호", content: phoneTextField))
        contentStack.addArrangedSubview(wrapWithLabel("사업자등록번호", content: businessContainer))
        contentStack.addArrangedSubview(businessNumberStatusLabel)
        
        // 회원가입 버튼
        nextButton.setTitle("회원가입", for: .normal)
        nextButton.setTitleColor(.white, for: .normal)
        nextButton.backgroundColor = themeColor
        nextButton.layer.cornerRadius = 8
        nextButton.isEnabled = false
        nextButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(nextButton)
        
        // Auto Layout
        NSLayoutConstraint.activate([
            // 스크롤 뷰
            scrollView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: nextButton.topAnchor, constant: -12),
            
            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 24),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor, constant: 24),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor, constant: -24),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -48),
            
            nextButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 24),
            nextButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -24),
            nextButton.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -24),
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
    
    // 키보드 위에 "완료" 버튼
    private func addDoneButtonToKeyboard(for textField: UITextField) {
        let toolbar = UIToolbar(); toolbar.sizeToFit()
        let flex = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let done = UIBarButtonItem(title: "완료", style: .done, target: textField, action: #selector(resignFirstResponder))
        toolbar.items = [flex, done]
        textField.inputAccessoryView = toolbar
    }
}
