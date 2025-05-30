//
//  EditRoomViewController.swift
//  FaceInn
//
//  Created by 신찬솔 on 5/31/25.
//

import UIKit
import PhotosUI
import FirebaseFirestore
import FirebaseStorage
import FirebaseAuth
import Kingfisher

import FirebaseFirestore

final class EditRoomViewController: UIViewController, UICollectionViewDataSource {
    
    private let editRoomView = RoomRegisterView()
    var roomId: String?
    
    override func loadView() {
        self.view = editRoomView
    }

    override func viewDidLoad() {
        self.title = "객실 정보 수정"
        super.viewDidLoad()
        editRoomView.collectionView.dataSource = self
        editRoomView.collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "Cell")
        fetchRoomData()
        editRoomView.selectImageButton.addTarget(self, action: #selector(selectImageTapped), for: .touchUpInside)
        editRoomView.registerButton.addTarget(self, action: #selector(updateRoom), for: .touchUpInside)
        self.hidesBottomBarWhenPushed = true
    }

    @objc private func updateRoom() {
        // Validation block
        guard !self.editRoomView.selectedImages.isEmpty else {
            showAlert(title: "오류", message: "최소 한 장 이상의 사진을 등록해주세요.")
            return
        }

        guard let name = self.editRoomView.nameTextField.text, !name.isEmpty,
              let priceString = self.editRoomView.addressTextField.text, !priceString.isEmpty,
              let description = self.editRoomView.descriptionTextField.text, !description.isEmpty,
              let capacityString = self.editRoomView.capacityTextField.text, !capacityString.isEmpty else {
            showAlert(title: "오류", message: "모든 객실 정보를 입력해주세요.")
            return
        }

        guard !self.editRoomView.selectedAmenities.isEmpty else {
            showAlert(title: "오류", message: "최소 하나 이상의 편의시설을 선택해주세요.")
            return
        }

        let confirmationAlert = UIAlertController(title: "확인", message: "객실을 수정하시겠습니까?", preferredStyle: .alert)
        confirmationAlert.addAction(UIAlertAction(title: "취소", style: .cancel))
        confirmationAlert.addAction(UIAlertAction(title: "수정", style: .default, handler: { _ in
            guard let userId = Auth.auth().currentUser?.uid, let roomId = self.roomId else { return }
            let db = Firestore.firestore()

            // Show loading indicator before starting uploads
            self.editRoomView.showLoading()

            // Image upload logic copied and adapted from RoomRegisterViewController
            let storage = Storage.storage()
            let dispatchGroup = DispatchGroup()
            var uploadedImageURLs: [String] = []
            for (idx, image) in self.editRoomView.selectedImages.enumerated() {
                dispatchGroup.enter()
                guard let imageData = image.jpegData(compressionQuality: 0.8) else {
                    dispatchGroup.leave()
                    continue
                }
                let imageRef = storage.reference().child("room_images/\(UUID().uuidString).jpg")
                imageRef.putData(imageData, metadata: nil) { _, error in
                    if let error = error {
                        print("Error uploading image: \(error)")
                        dispatchGroup.leave()
                        return
                    }
                    imageRef.downloadURL { url, error in
                        if let url = url {
                            uploadedImageURLs.append(url.absoluteString)
                        } else {
                            print("Error getting download URL: \(error?.localizedDescription ?? "")")
                        }
                        dispatchGroup.leave()
                    }
                }
            }

            dispatchGroup.notify(queue: .main) {
                db.collection("users").document(userId).getDocument { userSnapshot, error in
                    if let error = error {
                        print("Error fetching user document: \(error)")
                        self.editRoomView.hideLoading()
                        return
                    }

                    guard let userData = userSnapshot?.data(),
                          let accommodationId = userData["accommodationId"] as? String else {
                        print("No accommodationId found for user")
                        self.editRoomView.hideLoading()
                        return
                    }

                    let accommodationRef = db.collection("accommodations").document(accommodationId)

                    accommodationRef.getDocument { accSnapshot, error in
                        if let error = error {
                            print("Error fetching accommodation document: \(error)")
                            self.editRoomView.hideLoading()
                            return
                        }

                        guard var accData = accSnapshot?.data(),
                              var rooms = accData["rooms"] as? [[String: Any]] else {
                            print("No rooms data found")
                            self.editRoomView.hideLoading()
                            return
                        }

                        // Build updated room data
                        let updatedRoom: [String: Any] = [
                            "id": roomId,
                            "name": self.editRoomView.nameTextField.text ?? "",
                            "price": Int(self.editRoomView.addressTextField.text ?? "0") ?? 0,
                            "description": self.editRoomView.descriptionTextField.text ?? "",
                            "maxOccupancy": Int(self.editRoomView.capacityTextField.text ?? "1") ?? 1,
                            "checkInTime": self.formatTime(self.editRoomView.checkInPicker.date),
                            "checkOutTime": self.formatTime(self.editRoomView.checkOutPicker.date),
                            "amenities": Array(self.editRoomView.selectedAmenities),
                            "imageURLs": uploadedImageURLs
                        ]

                        // Replace existing room with updated one
                        if let index = rooms.firstIndex(where: { $0["id"] as? String == roomId }) {
                            rooms[index] = updatedRoom
                            accommodationRef.updateData(["rooms": rooms]) { error in
                                self.editRoomView.hideLoading()
                                if let error = error {
                                    print("Error updating room: \(error)")
                                } else {
                                    self.navigationController?.popViewController(animated: true)
                                    let alert = UIAlertController(title: "완료", message: "객실이 수정되었습니다.", preferredStyle: .alert)
                                    alert.addAction(UIAlertAction(title: "확인", style: .default))
                                    self.present(alert, animated: true)
                                }
                            }
                        } else {
                            print("Room with id \(roomId) not found in rooms array")
                            self.editRoomView.hideLoading()
                        }
                    }
                }
            }
        }))
        self.present(confirmationAlert, animated: true)
    }

    private func fetchRoomData() {
        guard let roomId = roomId, let userId = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()

        // Step 1: Get user's accommodationId
        db.collection("users").document(userId).getDocument { userSnapshot, error in
            if let error = error {
                print("Error fetching user document: \(error)")
                return
            }

            guard let userData = userSnapshot?.data(),
                  let accommodationId = userData["accommodationId"] as? String else {
                print("No accommodationId found for user")
                return
            }

            // Step 2: Get accommodations document and extract room by roomId
            db.collection("accommodations").document(accommodationId).getDocument { accSnapshot, error in
                if let error = error {
                    print("Error fetching accommodation document: \(error)")
                    return
                }

                guard let accData = accSnapshot?.data(),
                      let rooms = accData["rooms"] as? [[String: Any]] else {
                    print("No rooms data found in accommodation")
                    return
                }

                // Step 3: Find the specific room by roomId
                if let roomData = rooms.first(where: { $0["id"] as? String == roomId }) {
                    self.populateView(with: roomData)
                } else {
                    print("Room with id \(roomId) not found")
                }
            }
        }
    }

    private func populateView(with data: [String: Any]) {
        editRoomView.nameTextField.text = data["name"] as? String
        editRoomView.addressTextField.text = "\(data["price"] ?? "")"
        editRoomView.descriptionTextField.text = data["description"] as? String
        editRoomView.capacityTextField.text = "\(data["maxOccupancy"] ?? "")"

        if let checkInTimestamp = data["checkIn"] as? Timestamp {
            editRoomView.checkInPicker.date = checkInTimestamp.dateValue()
        }
        if let checkOutTimestamp = data["checkOut"] as? Timestamp {
            editRoomView.checkOutPicker.date = checkOutTimestamp.dateValue()
        }

        if let amenities = data["amenities"] as? [String] {
            for button in editRoomView.amenitiesStackView.arrangedSubviews.flatMap({ ($0 as? UIStackView)?.arrangedSubviews ?? [] }) {
                if let button = button as? UIButton,
                   let title = button.title(for: .normal),
                   amenities.contains(title) {
                    editRoomView.toggleAmenity(button)
                }
            }
        }
        if let imageURLs = data["imageURLs"] as? [String] {
            var loadedImages: [UIImage] = []
            let dispatchGroup = DispatchGroup()

            for urlString in imageURLs {
                guard let url = URL(string: urlString) else { continue }
                dispatchGroup.enter()
                let imageView = UIImageView()
                imageView.kf.setImage(with: url) { result in
                    switch result {
                    case .success(let value):
                        loadedImages.append(value.image)
                    case .failure(let error):
                        print("Kingfisher error: \(error)")
                    }
                    dispatchGroup.leave()
                }
            }

            dispatchGroup.notify(queue: .main) {
                self.editRoomView.selectedImages = loadedImages
                self.editRoomView.collectionView.reloadData()
                self.editRoomView.photoCountLabel.text = "\(loadedImages.count) / 10"
            }
        }
        editRoomView.registerButton.setTitle("수정하기", for: .normal)
    }
    
    public func configure(with roomId: String) {
        self.roomId = roomId
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return editRoomView.selectedImages.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath)
        cell.contentView.subviews.forEach { $0.removeFromSuperview() }

        let imageView = UIImageView(image: editRoomView.selectedImages[indexPath.item])
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
        guard index < editRoomView.selectedImages.count else { return }
        editRoomView.selectedImages.remove(at: index)
        editRoomView.collectionView.reloadData()
        editRoomView.photoCountLabel.text = "\(editRoomView.selectedImages.count) / 10"
    }

    @objc private func selectImageTapped() {
        if editRoomView.selectedImages.count >= 10 {
            let alert = UIAlertController(title: "알림", message: "사진은 최대 10장까지 등록 가능합니다.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "확인", style: .default))
            present(alert, animated: true)
            return
        }

        var config = PHPickerConfiguration()
        config.selectionLimit = 10 - editRoomView.selectedImages.count
        config.filter = .images
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }
}

extension EditRoomViewController: PHPickerViewControllerDelegate {
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
                        if self.editRoomView.selectedImages.count < 10 {
                            self.editRoomView.selectedImages.append(image)
                        }
                    }
                }
            }
        }
        group.notify(queue: .main) { [weak self] in
            guard let self = self else { return }
            self.editRoomView.collectionView.reloadData()
            self.editRoomView.photoCountLabel.text = "\(self.editRoomView.selectedImages.count) / 10"
        }
    }
}



extension EditRoomViewController {
    // MARK: - Helper
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

// MARK: - Alert Helper
private extension EditRoomViewController {
    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
}


    // Helper property for image URLs (customize as needed)
    private var imageURLs: [String] {
        // You can customize this logic if you're storing new image uploads
        return [] // Placeholder: integrate with your actual upload logic if applicable
    }
