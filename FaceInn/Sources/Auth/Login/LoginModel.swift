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

    func login(email: String, password: String, completion: @escaping (Result<Void, Error>) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let uid = result?.user.uid else {
                completion(.failure(NSError(domain: "Login", code: -1, userInfo: [NSLocalizedDescriptionKey: "사용자 정보를 가져올 수 없습니다."])))
                return
            }
            self.updateUserSession(uid: uid, completion: completion)
        }
    }

    private func updateUserSession(uid: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let ref = db.collection("users").document(uid)
        ref.setData([
            "loginStatus": true,
            "lastLogin": Timestamp(date: Date())
        ], merge: true) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
}
