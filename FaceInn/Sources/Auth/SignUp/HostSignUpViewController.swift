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
            return
        }
        checkBusinessNumberValidation(num) { valid, status in
            DispatchQueue.main.async {
                let v = self.hostSignUpView
                if valid {
                    self.model.isBusinessNumberValid = true
                    v.businessNumberStatusLabel.text = status
                    v.businessNumberStatusLabel.textColor = .systemGreen
                    v.businessNumberTextField.isEnabled = false
                    v.verifyBusinessNumberButton.isEnabled = false
                    v.verifyBusinessNumberButton.setTitleColor(.systemGray, for: .disabled)
                    v.verifyBusinessNumberButton.layer.borderColor = UIColor.systemGray.cgColor
                } else {
                    self.model.isBusinessNumberValid = false
                    v.businessNumberStatusLabel.text = status
                    v.businessNumberStatusLabel.textColor = .systemRed
                }
                self.updateNextButtonState()
            }
        }
    }

    // 회원가입
    @objc private func didTapNext() {
        let db = Firestore.firestore()
        let data: [String:Any] = [
            "email": model.email,
            "name": model.name,
            "phone": model.phone,
            "businessNumber": model.businessNumber,
            "type": "host"
        ]
        db.collection("users").addDocument(data: data) { err in
            if let err = err { self.showAlert("저장 실패: \(err)"); return }
            print("호스트 가입 완료")
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

    @objc private func keyboardWillShow(_ n: Notification) {
        guard let f = n.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        hostSignUpView.scrollView.contentInset.bottom = f.height + 20
        hostSignUpView.scrollView.scrollIndicatorInsets.bottom = f.height + 20
    }

    @objc private func keyboardWillHide(_ n: Notification) {
        hostSignUpView.scrollView.contentInset = .zero
        hostSignUpView.scrollView.scrollIndicatorInsets = .zero
    }

    // MARK: - UITextFieldDelegate

    // 키보드 활성화 시, 필드 이동
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if textField == hostSignUpView.businessNumberTextField {
            UIView.animate(withDuration: 0.3) {
                self.view.frame.origin.y = -50
            }
        }
    }

    // 키보드 비활성화 시, 필드 복귀
    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField == hostSignUpView.businessNumberTextField {
            UIView.animate(withDuration: 0.3) {
                self.view.frame.origin.y = 0
            }
        }
    }
}

// 사업자등록번호 API 호출
private extension HostSignUpViewController {
    func checkBusinessNumberValidation(_ number: String,
        completion: @escaping (Bool, String) -> Void
    ) {
        let apiKey = "<YOUR_ENCODED_SERVICE_KEY>"
        let urlStr = "https://api.odcloud.kr/api/nts-businessman/v1/status?serviceKey=\(apiKey)"
        guard let url = URL(string: urlStr) else {
            return completion(false, "URL 생성 실패")
        }
        var req = URLRequest(url: url); req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = ["b_no": [number]]
        req.httpBody = try? JSONSerialization.data(withJSONObject: body)
        URLSession.shared.dataTask(with: req) { data, _, err in
            if let err = err { return completion(false, "네트워크 오류") }
            guard let d = data,
                  let json = try? JSONSerialization.jsonObject(with: d) as? [String:Any],
                  let arr = json["data"] as? [[String:Any]],
                  let r = arr.first,
                  let code = r["b_stt_cd"] as? String else {
                return completion(false, "파싱 실패")
            }
            if code == "01" {
                completion(true, "유효한 사업자등록번호입니다.")
            } else {
                completion(false, "현재 운영 중인 사업자등록번호를 입력해주세요.")
            }
        }.resume()
    }
}
