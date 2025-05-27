
//
//  ProfileViewController.swift
//  FaceInn
//
//  Created by 신찬솔 on 5/18/25.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore
import AVFoundation

final class ProfileViewController: UIViewController {

    private let profileView = ProfileView()

    override func loadView() {
        view = profileView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "마이페이지"
        profileView.loginButton.addTarget(self, action: #selector(didTapLogin), for: .touchUpInside)
        profileView.faceIDLoginButton.addTarget(self, action: #selector(didTapLogin), for: .touchUpInside)
        profileView.logoutButton.addTarget(self, action: #selector(didTapLogout), for: .touchUpInside)
        profileView.faceIDRegisterButton.addTarget(self, action: #selector(didTapFaceIDAction), for: .touchUpInside)
        updateView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateView()
    }

    // 로그인 상태에 따라 UI 업데이트
    private func updateView() {
        if let user = Auth.auth().currentUser {
            profileView.configureView(isLoggedIn: true)
            let db = Firestore.firestore()
            db.collection("users").document(user.uid).getDocument { snapshot, error in
                if let data = snapshot?.data() {
                    self.profileView.nameLabel.text = "\(data["name"] as? String ?? "사용자")님"
                    self.profileView.emailLabel.text = data["email"] as? String ?? user.email ?? ""

                    let hasFaceID = data["left_vector"] != nil && data["front_vector"] != nil && data["right_vector"] != nil
                    self.profileView.faceIDLabel.text = hasFaceID ? "얼굴 정보 등록됨" : "얼굴 정보 미등록"
                    self.profileView.faceIDSubLabel.text = hasFaceID
                        ? "얼굴 정보를 통해 빠르고 편리하게 체크인할 수 있습니다."
                        : "얼굴 정보를 등록하면 빠른 체크인이 가능합니다."
                    self.profileView.faceIDRegisterButton.setTitle(hasFaceID ? "삭제하기" : "등록하기", for: .normal)
                }
            }
        } else {
            profileView.configureView(isLoggedIn: false)
        }
    }
    // 페이스 아이디 등록/삭제 버튼 액션
    @objc private func didTapFaceIDAction() {
        guard let user = Auth.auth().currentUser else { return }
        let db = Firestore.firestore()
        db.collection("users").document(user.uid).getDocument { snapshot, error in
            guard let data = snapshot?.data() else { return }
            let hasFaceID = data["left_vector"] != nil && data["front_vector"] != nil && data["right_vector"] != nil

            if hasFaceID {
                let alert = UIAlertController(title: "삭제 확인", message: "얼굴 정보를 삭제하시겠습니까?", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "취소", style: .cancel))
                alert.addAction(UIAlertAction(title: "확인", style: .destructive) { _ in
                    db.collection("users").document(user.uid).updateData([
                        "left_vector": FieldValue.delete(),
                        "front_vector": FieldValue.delete(),
                        "right_vector": FieldValue.delete()
                    ]) { error in
                        if let error = error {
                            print("삭제 실패: \(error)")
                        } else {
                            print("얼굴 정보 삭제됨")
                            self.updateView()
                            // 얼굴 정보 삭제 성공 시 reserves 컬렉션의 useFaceId 값을 false로 업데이트
                            let reservesRef = db.collection("reserves")
                            reservesRef.whereField("userId", isEqualTo: user.uid)
                                .whereField("useFaceId", isEqualTo: true)
                                .getDocuments { snapshot, error in
                                    guard let documents = snapshot?.documents else { return }
                                    let now = Date()
                                    for doc in documents {
                                        if let endDate = (doc.data()["endDate"] as? Timestamp)?.dateValue(),
                                           endDate > now {
                                            reservesRef.document(doc.documentID).updateData(["useFaceId": false])
                                        }
                                    }
                                }
                        }
                    }
                })
                self.present(alert, animated: true)
            } else {
                self.didTapFaceIDRegister()
            }
        }
    }

    // 로그인 화면으로 이동
    @objc private func didTapLogin() {
        let loginVC = LoginViewController()
        navigationController?.pushViewController(loginVC, animated: true)
    }

    // 로그아웃 처리 및 UI 갱신
    @objc private func didTapLogout() {
        do {
            try Auth.auth().signOut()
            updateView()
        } catch {
            print("Logout failed: \(error.localizedDescription)")
        }
    }
    
    @objc private func didTapFaceIDRegister() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            let vc = FaceCaptureViewController()
            navigationController?.pushViewController(vc, animated: true)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        let vc = FaceCaptureViewController()
                        self.navigationController?.pushViewController(vc, animated: true)
                    } else {
                        self.showCameraAccessAlert()
                    }
                }
            }
        case .denied, .restricted:
            showCameraAccessAlert()
        @unknown default:
            break
        }
    }

    private func showCameraAccessAlert() {
        let alert = UIAlertController(
            title: "카메라 권한 필요",
            message: "얼굴 정보 등록을 위해 설정에서 카메라 접근 권한을 허용해주세요.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        alert.addAction(UIAlertAction(title: "설정으로 이동", style: .default, handler: { _ in
            if let url = URL(string: UIApplication.openSettingsURLString),
               UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            }
        }))
        present(alert, animated: true)
    }
}
