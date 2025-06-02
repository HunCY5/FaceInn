//
//  SignUpViewController.swift
//  FaceInn
//
//  Created by CHOI on 5/20/25.
//

import UIKit

final class SignUpViewController: UIViewController {

    private let signUpView = SignUpView()
    private let model = SignUpModel()

    private var isEmailAvailable = false

    override func loadView() {
        view = signUpView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "회원가입"
        configureActions()
    }

    private func configureActions() {
        signUpView.checkEmailButton.addTarget(self, action: #selector(didTapCheckEmail), for: .touchUpInside)
        signUpView.signUpButton.addTarget(self, action: #selector(didTapSignUp), for: .touchUpInside)

        // 입력 값이 변경될 때마다 유효성 확인
        [signUpView.nameTextField,
         signUpView.birthdayTextField,
         signUpView.phoneTextField,
         signUpView.emailTextField,
         signUpView.passwordTextField,
         signUpView.confirmPasswordTextField
        ].forEach { tf in
            tf.addTarget(self, action: #selector(textFieldChanged), for: .editingChanged)
        }
    }

    @objc private func textFieldChanged() {
        let name = signUpView.nameTextField.text ?? ""
        let birthday = signUpView.birthdayString
        let phone = signUpView.phoneTextField.text ?? ""
        let email = signUpView.emailTextField.text ?? ""
        let password = signUpView.passwordTextField.text ?? ""
        let confirm = signUpView.confirmPasswordTextField.text ?? ""

        if !confirm.isEmpty {
            if password == confirm {
                signUpView.passwordMatchLabel.text = "비밀번호가 일치합니다."
                signUpView.passwordMatchLabel.textColor = .systemGreen
            } else {
                signUpView.passwordMatchLabel.text = "비밀번호가 일치하지 않습니다."
                signUpView.passwordMatchLabel.textColor = .red
            }
        } else {
            signUpView.passwordMatchLabel.text = ""
        }

        let isFormValid = !name.isEmpty &&
                          !birthday.isEmpty &&
                          phone.count >= 10 &&
                          phone.count <= 11 &&
                          phone.allSatisfy { $0.isNumber } &&
                          model.isValidEmail(email) &&
                          password.count >= 6 &&
                          password == confirm &&
                          isEmailAvailable

        signUpView.signUpButton.isEnabled = isFormValid
        signUpView.signUpButton.backgroundColor = isFormValid ? .systemGreen : .lightGray
    }

    @objc private func didTapCheckEmail() {
        let email = signUpView.emailTextField.text ?? ""
        guard model.isValidEmail(email) else {
            signUpView.statusLabel.text = "유효하지 않은 이메일 형식입니다."
            signUpView.statusLabel.textColor = .red
            isEmailAvailable = false
            textFieldChanged()
            return
        }

        model.checkEmailAvailability(email: email) { [weak self] isAvailable in
            DispatchQueue.main.async {
                if isAvailable {
                    self?.signUpView.statusLabel.text = "사용 가능한 이메일입니다."
                    self?.signUpView.statusLabel.textColor = .systemGreen
                    self?.isEmailAvailable = true
                } else {
                    self?.signUpView.statusLabel.text = "이미 가입된 이메일입니다."
                    self?.signUpView.statusLabel.textColor = .red
                    self?.isEmailAvailable = false
                }
                self?.textFieldChanged()
            }
        }
    }

    @objc private func didTapSignUp() {
        let name = signUpView.nameTextField.text ?? ""
        let birthday = signUpView.birthdayString
        let phone = signUpView.phoneTextField.text ?? ""
        let email = signUpView.emailTextField.text ?? ""
        let password = signUpView.passwordTextField.text ?? ""

        model.signUp(email: email, password: password, realName: name, birthday: birthday, phone: phone) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    let alert = UIAlertController(title: "회원가입 성공", message: "로그인 화면으로 이동합니다.", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "확인", style: .default) { _ in
                        self?.navigationController?.popViewController(animated: true)
                    })
                    self?.present(alert, animated: true)
                case .failure(let error):
                    let alert = UIAlertController(title: "회원가입 실패", message: error.localizedDescription, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "확인", style: .default))
                    self?.present(alert, animated: true)
                }
            }
        }
    }
}


#Preview {
    SignUpViewController()
}

