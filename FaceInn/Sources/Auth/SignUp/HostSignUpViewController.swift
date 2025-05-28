//
//  HostSignUpViewController.swift
//  FaceInn
//
//  Created by CHOI on 5/24/25.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

final class HostSignUpViewController: UIViewController, UITextFieldDelegate {

    private let keyboardScrollMargin: CGFloat = 20

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
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)),
                                               name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)),
                                               name: UIResponder.keyboardWillHideNotification, object: nil)
        hostSignUpView.phoneTextField.delegate = self
        hostSignUpView.businessNumberTextField.delegate = self
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Actions

    private func setupActions() {
        let v = hostSignUpView
        v.emailCheckButton.addTarget(self, action: #selector(checkEmailDuplication), for: .touchUpInside)
        v.verifyBusinessNumberButton.addTarget(self, action: #selector(verifyBusinessNumber), for: .touchUpInside)
        v.nextButton.addTarget(self, action: #selector(didTapNext), for: .touchUpInside)
        
        [v.emailTextField, v.passwordTextField, v.confirmPasswordTextField,
         v.nameTextField, v.phoneTextField, v.businessNumberTextField].forEach {
            $0.addTarget(self, action: #selector(textFieldChanged(_:)), for: .editingChanged)
        }
        v.passwordToggleButton.addTarget(self, action: #selector(togglePasswordVisibility), for: .touchUpInside)
        v.confirmPasswordToggleButton.addTarget(self, action: #selector(toggleConfirmPasswordVisibility), for: .touchUpInside)
    }

    @objc private func textFieldChanged(_ tf: UITextField) {
        let v = hostSignUpView
        model.email = v.emailTextField.text ?? ""
        model.password = v.passwordTextField.text ?? ""
        model.confirmPassword = v.confirmPasswordTextField.text ?? ""
        model.name = v.nameTextField.text ?? ""
        model.phone = v.phoneTextField.text ?? ""
        model.businessNumber = v.businessNumberTextField.text ?? ""
        
        v.passwordMismatchLabel.isHidden = (model.password == model.confirmPassword)
        
        // 이메일 포맷 실시간 체크
        let isEmailValid = NSPredicate(format: "SELF MATCHES %@", "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}")
            .evaluate(with: model.email)
        v.emailFormatLabel.isHidden = model.email.isEmpty
        v.emailFormatLabel.text = isEmailValid ? "올바른 이메일 형식입니다." : "올바른 이메일 형식이 아닙니다."
        v.emailFormatLabel.textColor = isEmailValid ? .systemGreen : .systemRed
        v.emailCheckButton.isEnabled = isEmailValid
        
        updateNextButtonState()
    }

    @objc private func togglePasswordVisibility() {
        let v = hostSignUpView
        v.passwordTextField.isSecureTextEntry.toggle()
        let name = v.passwordTextField.isSecureTextEntry ? "eye.slash" : "eye"
        v.passwordToggleButton.setImage(UIImage(systemName: name), for: .normal)
    }

    @objc private func toggleConfirmPasswordVisibility() {
        let v = hostSignUpView
        v.confirmPasswordTextField.isSecureTextEntry.toggle()
        let name = v.confirmPasswordTextField.isSecureTextEntry ? "eye.slash" : "eye"
        v.confirmPasswordToggleButton.setImage(UIImage(systemName: name), for: .normal)
    }

    // 이메일 중복 확인 (Firestore)
    @objc private func checkEmailDuplication() {
        let email = model.email.trimmingCharacters(in: .whitespaces)
        guard !email.isEmpty else { return showAlert("이메일을 입력해주세요.") }
        let db = Firestore.firestore()
        db.collection("users").whereField("email", isEqualTo: email).getDocuments { snap, err in
            if let err = err { return self.showAlert("오류: \(err.localizedDescription)") }
            if let docs = snap?.documents, !docs.isEmpty {
                self.showAlert("이미 존재하는 이메일입니다.")
                self.model.isEmailChecked = false
            } else {
                self.showAlert("사용 가능한 이메일입니다.")
                self.model.isEmailChecked = true
                let v = self.hostSignUpView
                v.emailTextField.isEnabled = false
                v.emailCheckButton.isEnabled = false
                v.emailCheckButton.setTitleColor(.systemGray, for: .disabled)
                v.emailCheckButton.layer.borderColor = UIColor.systemGray.cgColor
            }
            self.updateNextButtonState()
        }
    }

    // 사업자등록번호 검증
    @objc private func verifyBusinessNumber() {
        let num = model.businessNumber.filter { $0.isNumber }
        guard num.count == 10 else {
            hostSignUpView.businessNumberStatusLabel.text = "사업자등록번호는 숫자 10자리여야 합니다."
            hostSignUpView.businessNumberStatusLabel.textColor = .systemRed
            model.isBusinessNumberValid = false
            updateNextButtonState()
            return
        }
        let db = Firestore.firestore()
        // 먼저 Firestore에 동일한 사업자등록번호가 있는지 확인
        db.collection("users").whereField("businessNumber", isEqualTo: num).getDocuments { snap, err in
            if let err = err {
                DispatchQueue.main.async {
                    self.hostSignUpView.businessNumberStatusLabel.text = "오류: \(err.localizedDescription)"
                    self.hostSignUpView.businessNumberStatusLabel.textColor = .systemRed
                    self.model.isBusinessNumberValid = false
                    self.updateNextButtonState()
                }
                return
            }
            if let docs = snap?.documents, !docs.isEmpty {
                DispatchQueue.main.async {
                    self.hostSignUpView.businessNumberStatusLabel.text = "이미 등록된 사업자등록번호입니다."
                    self.hostSignUpView.businessNumberStatusLabel.textColor = .systemRed
                    self.model.isBusinessNumberValid = false
                    self.updateNextButtonState()
                }
            } else {
                // 기존 API 검증 호출
                self.checkBusinessNumberValidation(num) { valid, status in
                    DispatchQueue.main.async {
                        if valid {
                            self.model.isBusinessNumberValid = true
                            let v = self.hostSignUpView
                            v.businessNumberStatusLabel.text = status
                            v.businessNumberStatusLabel.textColor = .systemGreen
                            v.businessNumberTextField.isEnabled = false
                            v.verifyBusinessNumberButton.isEnabled = false
                            v.verifyBusinessNumberButton.setTitleColor(.systemGray, for: .disabled)
                            v.verifyBusinessNumberButton.layer.borderColor = UIColor.systemGray.cgColor
                        } else {
                            self.model.isBusinessNumberValid = false
                            self.hostSignUpView.businessNumberStatusLabel.text = status
                            self.hostSignUpView.businessNumberStatusLabel.textColor = .systemRed
                        }
                        self.updateNextButtonState()
                    }
                }
            }
        }
    }

    // 회원가입
    @objc private func didTapNext() {
        // Firebase Auth 계정 생성
        Auth.auth().createUser(withEmail: model.email, password: model.password) { [weak self] authResult, error in
            guard let self = self else { return }
            if let error = error {
                return self.showAlert("회원가입 오류: \(error.localizedDescription)")
            }
            // Auth 성공 시 Firestore에 사용자 정보 저장
            let uid = authResult?.user.uid ?? UUID().uuidString
            let db = Firestore.firestore()
            let data: [String: Any] = [
                "email": self.model.email,
                "name": self.model.name,
                "phone": self.model.phone,
                "businessNumber": self.model.businessNumber,
                "type": "host",
                "uid": uid
            ]
            db.collection("users").document(uid).setData(data) { err in
                if let err = err {
                    self.showAlert("저장 실패: \(err.localizedDescription)")
                } else {
                    DispatchQueue.main.async {
                        let alert = UIAlertController(title: nil, message: "회원가입이 완료되었습니다.", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "확인", style: .default) { _ in
                            // 회원가입 직후 로그아웃 처리
                            do {
                                try Auth.auth().signOut()
                            } catch {
                                print("Sign-out after sign-up failed: \(error)")
                            }
                            UserDefaults.standard.set("guest", forKey: "userType")
                            self.navigationController?.popViewController(animated: true)
                        })
                        self.present(alert, animated: true)
                    }
                }
            }
        }
    }

    private func updateNextButtonState() {
        let v = hostSignUpView.nextButton
        if model.canProceed {
            v.isEnabled = true
            v.backgroundColor = UIColor(red: 47/255, green: 175/255, blue: 83/255, alpha: 1)
        } else {
            v.isEnabled = false
            v.backgroundColor = .systemGray3
        }
    }

    private func showAlert(_ msg: String) {
        let a = UIAlertController(title: nil, message: msg, preferredStyle: .alert)
        a.addAction(.init(title: "확인", style: .default))
        present(a, animated: true)
    }

    // MARK: - 키보드 처리

    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let kbFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        
        // 1) 키보드 높이만큼 스크롤뷰 인셋 조정
        let inset = kbFrame.height - view.safeAreaInsets.bottom
        hostSignUpView.scrollView.contentInset.bottom = inset
        hostSignUpView.scrollView.verticalScrollIndicatorInsets.bottom = inset

        // 2) 사업자등록번호 필드가 키보드에 가려지지 않도록 오프셋 계산
        let fieldFrame = hostSignUpView.businessNumberTextField.convert(
            hostSignUpView.businessNumberTextField.bounds,
            to: hostSignUpView.scrollView
        )
        // 가시 영역(스크롤뷰 높이에서 인셋을 뺀 값)
        let visibleHeight = hostSignUpView.scrollView.bounds.height - inset
        // 필드 하단이 키보드 바로 위로 오도록 오프셋 계산
        let offsetY = fieldFrame.maxY - visibleHeight + keyboardScrollMargin

        // 3) 필요하면 스크롤
        if offsetY > 0 {
            hostSignUpView.scrollView.setContentOffset(.init(x: 0, y: offsetY), animated: true)
        }
    }

    @objc private func keyboardWillHide(_ n: Notification) {
        hostSignUpView.scrollView.contentInset = .zero
        hostSignUpView.scrollView.scrollIndicatorInsets = .zero
    }

}

// 사업자등록번호 API 호출
private extension HostSignUpViewController {
    func checkBusinessNumberValidation(_ number: String,
        completion: @escaping (Bool, String) -> Void
    ) {
        let apiKey = "fbK2g297uMEM8V6tRh8OrEcJYGYvS2aK%2FhLSkVSySexCD0yEVarZgDG7Li6ZbrOy1Wa%2B%2BIrb%2BdZHjwnpnSDHBA%3D%3D"
        let urlStr = "https://api.odcloud.kr/api/nts-businessman/v1/status?serviceKey=\(apiKey)"
        guard let url = URL(string: urlStr) else {
            return completion(false, "URL 생성 실패")
        }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = ["b_no": [number]]
        req.httpBody = try? JSONSerialization.data(withJSONObject: body)
        URLSession.shared.dataTask(with: req) { data, _, error in
            if let error = error {
                return completion(false, "네트워크 오류: \(error.localizedDescription)")
            }
            guard let d = data,
                  let obj = try? JSONSerialization.jsonObject(with: d) as? [String:Any],
                  let arr = obj["data"] as? [[String:Any]],
                  let first = arr.first,
                  let codeValue = first["b_stt_cd"] else {
                return completion(false, "파싱 실패")
            }
            let code: String
            if let s = codeValue as? String {
                code = s
            } else if let i = codeValue as? Int {
                code = String(i)
            } else {
                return completion(false, "파싱 실패")
            }
            if code == "01" {
                completion(true, "사용 가능한 사업자등록번호입니다.")
            } else {
                completion(false, "현재 운영 중인 사업자등록번호를 입력해주세요.")
            }
        }.resume()
    }
}

extension HostSignUpViewController {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        // 휴대폰 최대 11자리 숫자 제한
        if textField == hostSignUpView.phoneTextField {
            let currentText = textField.text ?? ""
            guard let stringRange = Range(range, in: currentText) else { return false }
            let updatedText = currentText.replacingCharacters(in: stringRange, with: string)
            let digitsCount = updatedText.filter { $0.isNumber }.count
            return digitsCount <= 11
        }
        // 사업자등록번호 최대 10자리 숫자 제한
        else if textField == hostSignUpView.businessNumberTextField {
            let currentText = textField.text ?? ""
            guard let stringRange = Range(range, in: currentText) else { return false }
            let updatedText = currentText.replacingCharacters(in: stringRange, with: string)
            let digitsCount = updatedText.filter { $0.isNumber }.count
            return digitsCount <= 10
        }
        return true
    }
}

