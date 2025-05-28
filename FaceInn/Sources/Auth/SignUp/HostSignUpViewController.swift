//
//  HostSignUpViewController.swift
//  FaceInn
//
//  Created by CHOI on 5/24/25.
//


import UIKit
import FirebaseAuth
import FirebaseFirestore

final class HostSignUpViewController: UIViewController {

    private let hostSignUpView = HostSignUpView()
    private let model = HostSignUpModel()

    override func loadView() {
        view = hostSignUpView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "호스트 회원가입"
        setupActions()
        updateNextButtonState()
    }

    private func setupActions() {
        hostSignUpView.emailCheckButton.addTarget(self, action: #selector(checkEmailDuplication), for: .touchUpInside)
        hostSignUpView.verifyBusinessNumberButton.addTarget(self, action: #selector(verifyBusinessNumber), for: .touchUpInside)
        hostSignUpView.nextButton.addTarget(self, action: #selector(didTapNext), for: .touchUpInside)

        [hostSignUpView.emailTextField,
         hostSignUpView.passwordTextField,
         hostSignUpView.confirmPasswordTextField,
         hostSignUpView.nameTextField,
         hostSignUpView.phoneTextField,
         hostSignUpView.businessNumberTextField
        ].forEach { field in
            field.addTarget(self, action: #selector(textFieldChanged(_:)), for: .editingChanged)
        }

        hostSignUpView.passwordToggleButton.addTarget(self, action: #selector(togglePasswordVisibility), for: .touchUpInside)
        hostSignUpView.confirmPasswordToggleButton.addTarget(self, action: #selector(toggleConfirmPasswordVisibility), for: .touchUpInside)
    }

    @objc private func textFieldChanged(_ sender: UITextField) {
        model.email = hostSignUpView.emailTextField.text ?? ""
        model.password = hostSignUpView.passwordTextField.text ?? ""
        model.confirmPassword = hostSignUpView.confirmPasswordTextField.text ?? ""
        model.name = hostSignUpView.nameTextField.text ?? ""
        model.phone = hostSignUpView.phoneTextField.text ?? ""
        model.businessNumber = hostSignUpView.businessNumberTextField.text ?? ""

        hostSignUpView.passwordMismatchLabel.isHidden = model.password == model.confirmPassword
        updateNextButtonState()
    }

    // 이메일 중복 확인
    @objc private func checkEmailDuplication() {
        let email = model.email.trimmingCharacters(in: .whitespaces)
        
        guard !email.isEmpty else {
            showAlert(message: "이메일을 입력해주세요.")
            return
        }

        let db = Firestore.firestore()
        db.collection("users").whereField("email", isEqualTo: email).getDocuments { snapshot, error in
            if let error = error {
                self.showAlert(message: "오류 발생: \(error.localizedDescription)")
                return
            }

            if let documents = snapshot?.documents, !documents.isEmpty {
                self.showAlert(message: "이미 존재하는 이메일입니다.")
                self.model.isEmailChecked = false
            } else {
                self.showAlert(message: "사용 가능한 이메일입니다.")
                self.model.isEmailChecked = true
                self.hostSignUpView.emailTextField.isEnabled = false
                self.hostSignUpView.emailCheckButton.isEnabled = false
                self.hostSignUpView.emailCheckButton.setTitleColor(.systemGray, for: .disabled)
                self.hostSignUpView.emailCheckButton.layer.borderColor = UIColor.systemGray.cgColor
            }

            self.updateNextButtonState()
        }
    }

    // 사업자 등록번호 형식 검증
    @objc private func verifyBusinessNumber() {
        let regex = "^\\d{3}-\\d{2}-\\d{5}$"
        let predicate = NSPredicate(format: "SELF MATCHES %@", regex)
        if predicate.evaluate(with: model.businessNumber) {
            model.isBusinessNumberValid = true
            hostSignUpView.businessNumberStatusLabel.text = "유효한 번호입니다."
            hostSignUpView.businessNumberStatusLabel.textColor = .systemGreen
            hostSignUpView.businessNumberTextField.isEnabled = false
            hostSignUpView.verifyBusinessNumberButton.isEnabled = false
            hostSignUpView.verifyBusinessNumberButton.setTitleColor(.systemGray, for: .disabled)
            hostSignUpView.verifyBusinessNumberButton.layer.borderColor = UIColor.systemGray.cgColor
        } else {
            model.isBusinessNumberValid = false
            hostSignUpView.businessNumberStatusLabel.text = "형식에 맞게 입력해주세요 (예: 123-45-67890)"
            hostSignUpView.businessNumberStatusLabel.textColor = .systemRed
        }
        updateNextButtonState()
    }

    // 비밀번호 텍스트 필드
    @objc private func togglePasswordVisibility() {
        hostSignUpView.passwordTextField.isSecureTextEntry.toggle()
        let imageName = hostSignUpView.passwordTextField.isSecureTextEntry ? "eye.slash" : "eye"
        hostSignUpView.passwordToggleButton.setImage(UIImage(systemName: imageName), for: .normal)
    }

    // 비밀번호 확인 텍스트 필드
    @objc private func toggleConfirmPasswordVisibility() {
        hostSignUpView.confirmPasswordTextField.isSecureTextEntry.toggle()
        let imageName = hostSignUpView.confirmPasswordTextField.isSecureTextEntry ? "eye.slash" : "eye"
        hostSignUpView.confirmPasswordToggleButton.setImage(UIImage(systemName: imageName), for: .normal)
    }

    // 사용자 정보 Firestore에 저장 + type: host
    @objc private func didTapNext() {
        let db = Firestore.firestore()
        let userData: [String: Any] = [
            "email": model.email,
            "name": model.name,
            "phone": model.phone,
            "businessNumber": model.businessNumber,
            "type": "host"
        ]
        db.collection("users").addDocument(data: userData) { error in
            if let error = error {
                self.showAlert(message: "회원 정보 저장 실패: \(error.localizedDescription)")
            } else {
                print("회원 정보 저장 성공")
            }
        }
    }

    private func updateNextButtonState() {
        if model.canProceed {
            hostSignUpView.nextButton.isEnabled = true
            hostSignUpView.nextButton.backgroundColor = UIColor(red: 47/255, green: 175/255, blue: 83/255, alpha: 1)
        } else {
            hostSignUpView.nextButton.isEnabled = false
            hostSignUpView.nextButton.backgroundColor = UIColor.systemGray3
        }
    }

    private func showAlert(message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
}
