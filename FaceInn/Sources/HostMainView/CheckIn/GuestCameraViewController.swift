//
//  GuestCameraViewController.swift
//  FaceInn
//
//  Created by CHOI on 6/2/25.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

final class GuestCameraViewController: UIViewController {
    // MARK: - Tap count for FaceInn button
    private var tapCount = 0
    private var firstTapTime: Date?

    // MARK: - UI Components
    private let checkinButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("체크인하기", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor(red: 46/255, green: 173/255, blue: 83/255, alpha: 1)
        button.layer.cornerRadius = 8
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let checkoutButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("체크아웃하기", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor(red: 46/255, green: 173/255, blue: 83/255, alpha: 1)
        button.layer.cornerRadius = 8
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let cameraIconView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "AppLogo")
        imageView.tintColor = UIColor(red: 46/255, green: 173/255, blue: 83/255, alpha: 1)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "FaceInn 체크인·체크아웃"
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "얼굴 인식으로 간편하게 체크인·체크아웃 하세요"
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 15/255, green: 25/255, blue: 40/255, alpha: 1) // 어두운 배경
        
        setupNavigationBar()
        setupLayout()
        
        // Button actions (customize with actual camera logic later)
        checkinButton.addTarget(self, action: #selector(didTapCheckin), for: .touchUpInside)
        checkoutButton.addTarget(self, action: #selector(didTapCheckout), for: .touchUpInside)
    }
    
    // MARK: - Navigation Bar 설정
    private func setupNavigationBar() {
        navigationItem.title = ""
        // Left bar button as text "FaceInn"
        let faceInnButton = UIBarButtonItem(title: "FaceInn", style: .plain, target: self, action: #selector(onFaceInnTapped))
        faceInnButton.tintColor = .white
        navigationItem.leftBarButtonItem = faceInnButton
        navigationController?.navigationBar.barTintColor = UIColor(red: 15/255, green: 25/255, blue: 40/255, alpha: 1)
        navigationController?.navigationBar.isTranslucent = false
        navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: UIColor.white]
    }
    
    // MARK: - Layout 설정
    private func setupLayout() {
        view.addSubview(cameraIconView)
        view.addSubview(titleLabel)
        view.addSubview(subtitleLabel)
        view.addSubview(checkinButton)
        view.addSubview(checkoutButton)
        
        NSLayoutConstraint.activate([
            // 카메라 아이콘 중앙
            cameraIconView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            cameraIconView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -100),
            cameraIconView.widthAnchor.constraint(equalToConstant: 80),
            cameraIconView.heightAnchor.constraint(equalToConstant: 80),
            
            // 타이틀
            titleLabel.topAnchor.constraint(equalTo: cameraIconView.bottomAnchor, constant: 16),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            // 서브타이틀
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            // 체크인 버튼
            checkinButton.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 24),
            checkinButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            checkinButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            checkinButton.heightAnchor.constraint(equalToConstant: 50),
            
            // 체크아웃 버튼
            checkoutButton.topAnchor.constraint(equalTo: checkinButton.bottomAnchor, constant: 16),
            checkoutButton.leadingAnchor.constraint(equalTo: checkinButton.leadingAnchor),
            checkoutButton.trailingAnchor.constraint(equalTo: checkinButton.trailingAnchor),
            checkoutButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    // MARK: - Button Actions
    @objc private func didTapCheckin() {
        let faceVC = GuestFaceRecognitionViewController()
        faceVC.recognitionType = .checkIn
        navigationController?.pushViewController(faceVC, animated: true)
    }
    
    @objc private func didTapCheckout() {
        let faceVC = GuestFaceRecognitionViewController()
        faceVC.recognitionType = .checkOut
        navigationController?.pushViewController(faceVC, animated: true)
    }
    
    @objc private func onFaceInnTapped() {
        let now = Date()

        if let first = firstTapTime {
            // "첫 탭 시각"으로부터 2초를 초과했다면 새 시퀀스 시작
            if now.timeIntervalSince(first) > 2.0 {
                firstTapTime = now
                tapCount = 1
            } else {
                // 여전히 2초 내라면 기존 시퀀스 유지하며 tapCount 증가
                tapCount += 1
            }
        } else {
            // 최초 탭이면 firstTapTime 설정, tapCount = 1
            firstTapTime = now
            tapCount = 1
        }

        // 5번 눌렀으면 인증 창 띄우고 tapCount 및 firstTapTime 초기화
        if tapCount >= 5 {
            firstTapTime = nil
            tapCount = 0
            presentPasswordAlert()
        }
    }
    
    private func presentPasswordAlert() {
        let alert = UIAlertController(title: "관리자 인증", message: "호스트 화면으로 돌아가려면 비밀번호를 입력하세요", preferredStyle: .alert)
        alert.addTextField { textField in
            textField.placeholder = "비밀번호 입력"
            textField.isSecureTextEntry = true
            textField.keyboardType = .numberPad
        }
        let okAction = UIAlertAction(title: "확인", style: .default) { _ in
            guard let input = alert.textFields?.first?.text, let uid = Auth.auth().currentUser?.uid else { return }
            let docRef = Firestore.firestore().collection("users").document(uid)
            docRef.getDocument { snapshot, error in
                if let data = snapshot?.data(), let storedPassword = data["guestPassword"] as? String {
                    if input == storedPassword {
                        // 인증 성공: CheckInViewController로 돌아가기
                        let checkinVC = /*CheckInViewController()*/
                        HostMainTabBarController()
                        let nav = UINavigationController(rootViewController: checkinVC)
                        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                           let delegate = scene.delegate as? SceneDelegate,
                           let window = delegate.window {
                            window.rootViewController = nav
                            window.makeKeyAndVisible()
                        }
                    } else {
                        let err = UIAlertController(title: "오류", message: "비밀번호가 일치하지 않습니다.", preferredStyle: .alert)
                        err.addAction(UIAlertAction(title: "확인", style: .default, handler: nil))
                        self.present(err, animated: true, completion: nil)
                    }
                } else {
                    let err = UIAlertController(title: "오류", message: "비밀번호를 가져오지 못했습니다.", preferredStyle: .alert)
                    err.addAction(UIAlertAction(title: "확인", style: .default, handler: nil))
                    self.present(err, animated: true, completion: nil)
                }
            }
        }
        let cancelAction = UIAlertAction(title: "취소", style: .cancel, handler: nil)
        alert.addAction(okAction)
        alert.addAction(cancelAction)
        present(alert, animated: true, completion: nil)
    }
}
