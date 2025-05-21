//
//  ProfileModel.swift
//  FaceInn
//
//  Created by CHOI on 5/22/25.
//

import FirebaseAuth
import FirebaseFirestore

final class ProfileModel {
    private let db = Firestore.firestore()

    func fetchUserProfile(completion: @escaping (String?, String?) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            completion(nil, nil)
            return
        }

        db.collection("users").document(uid).getDocument { snapshot, error in
            if let data = snapshot?.data() {
                let name = data["name"] as? String
                let email = data["email"] as? String
                completion(name, email)
            } else {
                completion(nil, nil)
            }
        }
    }

    func logout(completion: @escaping (Error?) -> Void) {
        do {
            try Auth.auth().signOut()
            completion(nil)
        } catch {
            completion(error)
        }
    }

    func isUserLoggedIn() -> Bool {
        return Auth.auth().currentUser != nil
    }
}
