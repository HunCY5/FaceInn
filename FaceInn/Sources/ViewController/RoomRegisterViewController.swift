//
//  RoomRegisterViewController.swift
//  FaceInn
//
//  Created by 신찬솔 on 5/31/25.
//

import UIKit
import PhotosUI
import FirebaseFirestore
import FirebaseStorage
import FirebaseAuth

final class RoomRegisterViewController: UIViewController {

    private let roomRegisterView = RoomRegisterView()

    override func loadView() {
        self.view = roomRegisterView
        roomRegisterView.registerButton.addTarget(self, action: #selector(registerRoom), for: .touchUpInside)
    }


    @objc private func registerRoom() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let userRef = Firestore.firestore().collection("users").document(userId)

        guard !roomRegisterView.selectedImages.isEmpty else {
            showAlert(title: "오류", message: "최소 한 장 이상의 사진을 등록해주세요.")
            return
        }

        guard let name = roomRegisterView.nameTextField.text, !name.isEmpty,
              let priceString = roomRegisterView.addressTextField.text, !priceString.isEmpty,
              let description = roomRegisterView.descriptionTextField.text, !description.isEmpty,
              let capacityString = roomRegisterView.capacityTextField.text, !capacityString.isEmpty else {
            showAlert(title: "오류", message: "모든 객실 정보를 입력해주세요.")
            return
        }

        guard !roomRegisterView.selectedAmenities.isEmpty else {
            showAlert(title: "오류", message: "최소 하나 이상의 편의시설을 선택해주세요.")
            return
        }

        let confirmationAlert = UIAlertController(title: "확인", message: "객실을 등록하시겠습니까?", preferredStyle: .alert)
        confirmationAlert.addAction(UIAlertAction(title: "취소", style: .cancel))
        confirmationAlert.addAction(UIAlertAction(title: "등록", style: .default, handler: { _ in
            userRef.getDocument { snapshot, error in
                guard let data = snapshot?.data(),
                      let accommodationId = data["accommodationId"] as? String else { return }

                self.roomRegisterView.showLoading()

                self.uploadImages { imageURLs in
                    let db = Firestore.firestore()
                    let roomId = String(format: "%06d", Int.random(in: 0...999999))
                    let roomData: [String: Any] = [
                        "id": roomId,
                        "name": name,
                        "price": Int(priceString) ?? 0,
                        "description": description,
                        "maxOccupancy": Int(capacityString) ?? 1,
                        "checkInTime": self.formatTime(self.roomRegisterView.checkInPicker.date),
                        "checkOutTime": self.formatTime(self.roomRegisterView.checkOutPicker.date),
                        "amenities": Array(self.roomRegisterView.selectedAmenities),
                        "imageURLs": imageURLs
                    ]

                    let accommodationRef = db.collection("accommodations").document(accommodationId)
                    accommodationRef.updateData([
                        "rooms": FieldValue.arrayUnion([roomData])
                    ]) { error in
                        self.roomRegisterView.hideLoading()
                        if let error = error {
                            print("Error saving room: \(error)")
                        } else {
                            self.navigationController?.popViewController(animated: true)
                        }
                    }
                }
            }
        }))
        present(confirmationAlert, animated: true)
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    private func uploadImages(completion: @escaping ([String]) -> Void) {
        let storage = Storage.storage()
        var imageURLs: [String] = []
        let dispatchGroup = DispatchGroup()

        for image in roomRegisterView.selectedImages {
            dispatchGroup.enter()

            guard let imageData = image.jpegData(compressionQuality: 0.8) else {
                dispatchGroup.leave()
                continue
            }

            let fileName = UUID().uuidString + ".jpg"
            let storageRef = storage.reference().child("roomImages/\(fileName)")

            storageRef.putData(imageData, metadata: nil) { _, error in
                if error != nil {
                    dispatchGroup.leave()
                    return
                }

                storageRef.downloadURL { url, _ in
                    if let url = url {
                        imageURLs.append(url.absoluteString)
                    }
                    dispatchGroup.leave()
                }
            }
        }

        dispatchGroup.notify(queue: .main) {
            completion(imageURLs)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.hidesBottomBarWhenPushed = true
        view.backgroundColor = .systemBackground
        self.title = "객실 추가"
        
        roomRegisterView.selectImageButton.addTarget(self, action: #selector(selectImageTapped), for: .touchUpInside)
        roomRegisterView.collectionView.dataSource = self
        roomRegisterView.collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "Cell")
    }
    
    @objc private func selectImageTapped() {
        if roomRegisterView.selectedImages.count >= 10 {
            let alert = UIAlertController(title: "알림", message: "사진은 최대 10장까지 등록 가능합니다.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "확인", style: .default))
            present(alert, animated: true)
            return
        }

        var config = PHPickerConfiguration()
        config.selectionLimit = 10 - roomRegisterView.selectedImages.count
        config.filter = .images
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
}

extension RoomRegisterViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return roomRegisterView.selectedImages.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath)
        cell.contentView.subviews.forEach { $0.removeFromSuperview() }

        let imageView = UIImageView(image: roomRegisterView.selectedImages[indexPath.item])
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.frame = cell.contentView.bounds
        cell.contentView.addSubview(imageView)

        let deleteButton = UIButton(type: .system)
        deleteButton.setTitle("✕", for: .normal)
        deleteButton.tintColor = .white
        deleteButton.backgroundColor = .black.withAlphaComponent(0.5)
        deleteButton.layer.cornerRadius = 12
        deleteButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .bold)
        deleteButton.frame = CGRect(x: cell.contentView.frame.width - 24, y: 0, width: 24, height: 24)
        deleteButton.tag = indexPath.item
        deleteButton.addTarget(self, action: #selector(deleteImageButtonTapped(_:)), for: .touchUpInside)
        cell.contentView.addSubview(deleteButton)

        return cell
    }

    @objc private func deleteImageButtonTapped(_ sender: UIButton) {
        deleteImage(sender.tag)
    }

    private func deleteImage(_ index: Int) {
        guard index < roomRegisterView.selectedImages.count else { return }
        roomRegisterView.selectedImages.remove(at: index)
        roomRegisterView.collectionView.reloadData()
        roomRegisterView.photoCountLabel.text = "\(roomRegisterView.selectedImages.count) / 10"
    }

}

extension RoomRegisterViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        let group = DispatchGroup()
        for result in results {
            group.enter()
            result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] reading, _ in
                defer { group.leave() }
                if let image = reading as? UIImage {
                    DispatchQueue.main.async {
                        guard let self = self else { return }
                        if self.roomRegisterView.selectedImages.count < 10 {
                            self.roomRegisterView.selectedImages.append(image)
                        }
                    }
                }
            }
        }
        group.notify(queue: .main) { [weak self] in
            guard let self = self else { return }
            self.roomRegisterView.collectionView.reloadData()
            self.roomRegisterView.photoCountLabel.text = "\(self.roomRegisterView.selectedImages.count) / 10"
        }
    }
}
