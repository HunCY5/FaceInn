//
//  ReservationCell.swift
//  FaceInn
//
//  Created by 신찬솔 on 5/30/25.
//

import UIKit
import FirebaseFirestore
import FirebaseAuth
import Kingfisher

class ReservationCell: UITableViewCell {
    let thumbnailImageView = UIImageView()
    let titleLabel = UILabel()
    let subtitleLabel = UILabel()
    let faceIdStatusLabel = UILabel()
    let checkInLabel = UILabel()
    let checkOutLabel = UILabel()
    let checkInDateLabel = UILabel()
    let checkOutDateLabel = UILabel()
    let cancelButton = UIButton(type: .system)
    let faceToggleSwitch = UISwitch()
    let faceToggleLabel = UILabel()

    var documentId: String?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        thumbnailImageView.translatesAutoresizingMaskIntoConstraints = false
        thumbnailImageView.contentMode = .scaleAspectFill
        thumbnailImageView.clipsToBounds = true
        thumbnailImageView.layer.cornerRadius = 8

        titleLabel.font = UIFont.boldSystemFont(ofSize: 16)
        subtitleLabel.font = UIFont.systemFont(ofSize: 14)
        subtitleLabel.textColor = .darkGray
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false

        faceIdStatusLabel.font = UIFont.systemFont(ofSize: 12)
        faceIdStatusLabel.textColor = .gray
        faceIdStatusLabel.translatesAutoresizingMaskIntoConstraints = false

        // 체크인/체크아웃 레이블
        checkInLabel.text = "체크인"
        checkInLabel.font = UIFont.systemFont(ofSize: 12)
        checkInLabel.textColor = .gray
        checkInDateLabel.font = UIFont.boldSystemFont(ofSize: 16)

        checkOutLabel.text = "체크아웃"
        checkOutLabel.font = UIFont.systemFont(ofSize: 12)
        checkOutLabel.textColor = .gray
        checkOutDateLabel.font = UIFont.boldSystemFont(ofSize: 16)

        // 예약 취소하기 버튼 설정
        cancelButton.setTitle("예약 취소하기", for: .normal)
        cancelButton.setTitleColor(.white, for: .normal)
        cancelButton.backgroundColor = .systemRed
        cancelButton.layer.cornerRadius = 8
        cancelButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 12)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.heightAnchor.constraint(equalToConstant: 30).isActive = true
        cancelButton.addTarget(self, action: #selector(handleCancelTapped), for: .touchUpInside)

        faceToggleSwitch.translatesAutoresizingMaskIntoConstraints = false
        faceToggleSwitch.addTarget(self, action: #selector(handleFaceSwitchChanged(_:)), for: .valueChanged)

        cancelButton.addTarget(self, action: #selector(buttonTouchDown(_:)), for: .touchDown)
        cancelButton.addTarget(self, action: #selector(buttonTouchUp(_:)), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        
        faceToggleLabel.text = "얼굴인식 체크인"
        faceToggleLabel.font = UIFont.systemFont(ofSize: 12)
        faceToggleLabel.textColor = .gray

        // 수평 스택
        let dateStack = UIStackView()
        let checkInStack = UIStackView(arrangedSubviews: [checkInLabel, checkInDateLabel])
        let checkOutStack = UIStackView(arrangedSubviews: [checkOutLabel, checkOutDateLabel])
        checkInStack.axis = .vertical
        checkOutStack.axis = .vertical
        dateStack.axis = .horizontal
        dateStack.distribution = .fillEqually
        dateStack.spacing = 8
        dateStack.addArrangedSubview(checkInStack)
        dateStack.addArrangedSubview(checkOutStack)

        let infoStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel, faceIdStatusLabel])
        infoStack.axis = .vertical
        infoStack.spacing = 2

        let faceToggleStack = UIStackView(arrangedSubviews: [faceToggleLabel, faceToggleSwitch])
        faceToggleStack.axis = .horizontal
        faceToggleStack.spacing = 0
        faceToggleStack.alignment = .center

        let buttonStack = UIStackView(arrangedSubviews: [faceToggleStack, cancelButton])
        buttonStack.axis = .horizontal
        buttonStack.spacing = 8
        buttonStack.distribution = .fillEqually

        let contentStack = UIStackView(arrangedSubviews: [infoStack, dateStack, buttonStack])
        contentStack.axis = .vertical
        contentStack.spacing = 12
        contentStack.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(thumbnailImageView)
        contentView.addSubview(contentStack)

        NSLayoutConstraint.activate([
            thumbnailImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            thumbnailImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            thumbnailImageView.widthAnchor.constraint(equalToConstant: 80),
            thumbnailImageView.heightAnchor.constraint(equalToConstant: 80),

            contentStack.leadingAnchor.constraint(equalTo: thumbnailImageView.trailingAnchor, constant: 12),
            contentStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            contentStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            contentStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    func showCancelButton(_ visible: Bool) {
        cancelButton.isHidden = !visible
    }

    @objc private func handleCancelTapped() {
        guard let viewController = self.findViewController() else { return }

        let alert = UIAlertController(title: "예약 취소", message: "예약을 취소하시겠습니까?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "취소", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "확인", style: .destructive, handler: { _ in
            self.cancelReservation()
        }))
        viewController.present(alert, animated: true)
    }

    @objc private func handleFaceSwitchChanged(_ sender: UISwitch) {
        guard let user = Auth.auth().currentUser,
              let docId = documentId,
              let viewController = self.findViewController() else { return }

        let db = Firestore.firestore()

        db.collection("users").document(user.uid).getDocument { userSnapshot, _ in
            let data = userSnapshot?.data()
            let hasVector = data?["front_vector"] != nil || data?["left_vector"] != nil || data?["right_vector"] != nil

            if !hasVector {
                sender.setOn(false, animated: true)
                let alert = UIAlertController(title: "얼굴 정보 없음", message: "얼굴을 등록해주세요.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "취소", style: .cancel))
                alert.addAction(UIAlertAction(title: "확인", style: .default) { _ in
                    let vc = FaceCaptureViewController()
                    vc.documentId = docId
                    viewController.navigationController?.pushViewController(vc, animated: true)
                })
                viewController.present(alert, animated: true)
                return
            }

            if sender.isOn {
                let alert = UIAlertController(title: "얼굴인식 체크인", message: "얼굴인식을 사용해서 체크인 하시겠습니까?", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "취소", style: .cancel) { _ in
                    sender.setOn(false, animated: true)
                })
                alert.addAction(UIAlertAction(title: "확인", style: .default) { _ in
                    db.collection("reserves").document(docId).updateData(["useFaceId": true])
                })
                viewController.present(alert, animated: true)
            } else {
                let alert = UIAlertController(title: "얼굴인식 체크인 해제", message: "얼굴인식 체크인을 사용하지 않으시겠습니까?", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "취소", style: .cancel) { _ in
                    sender.setOn(true, animated: true)
                })
                alert.addAction(UIAlertAction(title: "확인", style: .destructive) { _ in
                    db.collection("reserves").document(docId).updateData(["useFaceId": false])
                })
                viewController.present(alert, animated: true)
            }
        }
    }

    @objc private func updateUseFaceIdAfterCapture(_ notification: Notification) {
        guard let docId = notification.userInfo?["documentId"] as? String,
              let myDocId = self.documentId,
              docId == myDocId else { return }

        Firestore.firestore().collection("reserves").document(docId).updateData(["useFaceId": true]) { error in
            if let error = error {
                print("useFaceId 업데이트 실패: \(error)")
            } else {
                print("useFaceId가 true로 설정됨")
                NotificationCenter.default.post(name: NSNotification.Name("ReservationCancelled"), object: nil)
            }
        }
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name("FaceIdRegisteredWithDocId"), object: nil)
    }

    private func cancelReservation() {
        guard let docId = documentId else { return }
        Firestore.firestore().collection("reserves").document(docId).delete { error in
            if let error = error {
                print("예약 삭제 실패: \(error.localizedDescription)")
            } else {
                print("예약 취소됨")
                NotificationCenter.default.post(name: NSNotification.Name("ReservationCancelled"), object: nil)
            }
        }
    }


    // handleDisableFaceIdTapped 제거됨

    @objc private func buttonTouchDown(_ sender: UIButton) {
        UIView.animate(withDuration: 0.15,
                       delay: 0,
                       usingSpringWithDamping: 0.4,
                       initialSpringVelocity: 6,
                       options: .curveEaseInOut,
                       animations: {
            sender.transform = CGAffineTransform(scaleX: 0.93, y: 0.93)
        }, completion: nil)
    }

    @objc private func buttonTouchUp(_ sender: UIButton) {
        UIView.animate(withDuration: 0.25,
                       delay: 0,
                       usingSpringWithDamping: 0.5,
                       initialSpringVelocity: 2,
                       options: .curveEaseOut,
                       animations: {
            sender.transform = .identity
        }, completion: nil)
    }
}

