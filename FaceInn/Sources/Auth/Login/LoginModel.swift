//
//  LoginModel.swift
//  FaceInn
//
//  Created by CHOI on 5/20/25.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

final class LoginModel {
    private let db = Firestore.firestore()

    func login(email: String, password: String, completion: @escaping (Result<String, Error>) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let error = error as NSError? {
                let authError = AuthErrorCode.Code(rawValue: error.code)
                let message: String

                switch authError {
                case .userNotFound:
                    message = "계정이 존재하지 않습니다."
                case .wrongPassword:
                    message = "비밀번호를 다시 확인해주세요."
                case .invalidEmail:
                    message = "올바른 이메일 형식을 입력해주세요."
                default:
                    message = "이메일과 비밀번호를 확인해주세요."
                }

                completion(.failure(NSError(domain: "Login", code: error.code, userInfo: [NSLocalizedDescriptionKey: message])))
                return
            }

            guard let uid = result?.user.uid else {
                completion(.failure(NSError(domain: "Login", code: -1, userInfo: [NSLocalizedDescriptionKey: "사용자 정보를 가져올 수 없습니다."])))
                return
            }

            self.updateUserSession(uid: uid) { error in
                if let error = error {
                    completion(.failure(error))
                    return
                }

                let ref = self.db.collection("users").document(uid)
                ref.getDocument { snapshot, error in
                    if let error = error {
                        completion(.failure(error))
                        return
                    }
                    if let data = snapshot?.data(), let type = data["type"] as? String {
                        completion(.success(type))
                    } else {
                        completion(.failure(NSError(domain: "Login", code: -2, userInfo: [NSLocalizedDescriptionKey: "사용자 유형(type)을 찾을 수 없습니다."])))
                    }
                }
            }
        }
    }

    private func updateUserSession(uid: String, completion: @escaping (Error?) -> Void) {
        let ref = db.collection("users").document(uid)
        ref.setData([
            "loginStatus": true,
            "lastLogin": Timestamp(date: Date())
        ], merge: true) { error in
            completion(error)
        }
    }
}
