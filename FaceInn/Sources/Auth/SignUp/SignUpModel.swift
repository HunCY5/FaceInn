//
//  SignUpModel.swift
//  FaceInn
//
//  Created by CHOI on 5/20/25.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

final class SignUpModel {

    private let db = Firestore.firestore()

    func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let emailTest = NSPredicate(format: "SELF MATCHES %@", emailRegEx)
        return emailTest.evaluate(with: email)
    }

    func checkEmailAvailability(email: String, completion: @escaping (Bool) -> Void) {
        db.collection("users").whereField("email", isEqualTo: email).getDocuments { (querySnapshot, error) in
            if let error = error {
                print("❌ 이메일 중복 확인 실패: \(error.localizedDescription)")
                completion(false)
                return
            }
            completion(querySnapshot?.isEmpty == true)
        }
    }

    func signUp(email: String,
                password: String,
                realName: String,
                birthday: String?,
                completion: @escaping (Result<Void, Error>) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                print("❌ Firebase 회원가입 실패: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }

            guard let uid = result?.user.uid else {
                completion(.failure(NSError(domain: "SignUp", code: -1, userInfo: [NSLocalizedDescriptionKey: "사용자 정보를 가져올 수 없습니다."])))
                return
            }

            self.saveUserData(uid: uid, email: email, name: realName, birthday: birthday, completion: completion)
        }
    }

    private func saveUserData(uid: String,
                              email: String,
                              name: String,
                              birthday: String?,
                              completion: @escaping (Result<Void, Error>) -> Void) {
        var userData: [String: Any] = [
            "email": email,
            "name": name,
            "loginStatus": false,
            "createdAt": Timestamp(date: Date())
        ]
        if let birthday = birthday {
            userData["birthday"] = birthday
        }

        db.collection("users").document(uid).setData(userData) { error in
            if let error = error {
                print("❌ Firestore 저장 실패: \(error.localizedDescription)")
                completion(.failure(error))
            } else {
                print("✅ Firestore 저장 성공")
                completion(.success(()))
            }
        }
    }
}
