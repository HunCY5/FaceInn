//
//  EditAccommodationViewController.swift
//  FaceInn
//
//  Created by 신찬솔 on 5/31/25.
//


import UIKit
import Kingfisher
import PhotosUI
import FirebaseFirestore
import FirebaseStorage
import FirebaseAuth

class EditAccommodationViewController: UIViewController {

    private let editView = AccommodationRegisterView()

    override func loadView() {
        self.view = editView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "숙소 수정"
        editView.logoutButton.isHidden = true
        // Fetch accommodation data for current user before setting up view actions
        if let userId = Auth.auth().currentUser?.uid {
            let userRef = Firestore.firestore().collection("users").document(userId)
            userRef.getDocument { [weak self] snapshot, error in
                guard let self = self else { return }
                if let data = snapshot?.data(), let accommodationId = data["accommodationId"] as? String {
                    let accommodationRef = Firestore.firestore().collection("accommodations").document(accommodationId)
                    accommodationRef.getDocument { document, error in
                        if let docData = document?.data() {
                            self.editView.nameTextField.text = docData["name"] as? String ?? ""
                            self.editView.addressTextField.text = docData["location"] as? String ?? ""
                            self.editView.descriptionTextField.text = docData["description"] as? String ?? ""
                            if let amenities = docData["amenities"] as? [String] {
                                self.editView.selectedAmenities = Set(amenities)
                                DispatchQueue.main.async {
                                    for button in self.editView.amenityButtons {
                                        if let title = button.title(for: .normal), self.editView.selectedAmenities.contains(title) {
                                            button.backgroundColor = UIColor(red: 47/255, green: 175/255, blue: 83/255, alpha: 0.2)
                                        } else {
                                            button.backgroundColor = .clear
                                        }
                                    }
                                }
                            }
                            if let imageURLs = docData["imageURLs"] as? [String] {
                                for urlString in imageURLs {
                                    if let url = URL(string: urlString) {
                                        let imageView = UIImageView()
                                        imageView.kf.setImage(with: url) { result in
                                            switch result {
                                            case .success(let value):
                                                DispatchQueue.main.async {
                                                    self.editView.selectedImages.append(value.image)
                                                    self.editView.collectionView.reloadData()
                                                    self.editView.photoCountLabel.text = "\(self.editView.selectedImages.count) / 10"
                                                }
                                            case .failure(let error):
                                                print("Kingfisher failed to load image: \(error)")
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        editView.collectionView.dataSource = self
        editView.collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "Cell")
        editView.selectImageButton.addTarget(self, action: #selector(selectImageTapped), for: .touchUpInside)
        editView.registerButton.addTarget(self, action: #selector(registerAccommodation), for: .touchUpInside)

        editView.amenityButtonHandler = { [weak self] sender in
            guard let self = self else { return }
            self.toggleAmenity(sender)
        }
        editView.deleteImageHandler = { [weak self] index in
            self?.deleteImage(index)
        }
    }

    @objc private func registerAccommodation() {
        let confirmationAlert = UIAlertController(title: "확인", message: "숙소 정보를 수정 하시겠습니까?", preferredStyle: .alert)
        confirmationAlert.addAction(UIAlertAction(title: "취소", style: .cancel, handler: nil))
        confirmationAlert.addAction(UIAlertAction(title: "등록", style: .default, handler: { _ in
            self.performAccommodationRegistration()
        }))
        present(confirmationAlert, animated: true)
        return
    }
    
    private func performAccommodationRegistration() {
        editView.showLoading()
        let selectedImages = editView.selectedImages
        let selectedAmenities = editView.selectedAmenities
        guard !selectedImages.isEmpty else {
            editView.hideLoading()
            let alert = UIAlertController(title: "오류", message: "최소 한 장 이상의 사진을 등록해주세요.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "확인", style: .default))
            present(alert, animated: true)
            return
        }
        guard !selectedAmenities.isEmpty else {
            editView.hideLoading()
            let alert = UIAlertController(title: "오류", message: "최소 하나 이상의 편의시설을 선택해주세요.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "확인", style: .default))
            present(alert, animated: true)
            return
        }
        guard let name = editView.nameTextField.text, !name.isEmpty,
              let address = editView.addressTextField.text, !address.isEmpty,
              let description = editView.descriptionTextField.text, !description.isEmpty else {
            editView.hideLoading()
            let alert = UIAlertController(title: "오류", message: "모든 숙소 정보를 입력해주세요.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "확인", style: .default))
            present(alert, animated: true)
            return
        }

        guard let hostId = Auth.auth().currentUser?.uid else {
            print("로그인된 사용자 정보 없음")
            editView.hideLoading()
            return
        }
        let storageRef = Storage.storage().reference()
        var imageUrls: [String] = []
        let dispatchGroup = DispatchGroup()

        for image in selectedImages {
            guard let imageData = image.jpegData(compressionQuality: 0.8) else { continue }
            let imageID = UUID().uuidString
            let imageRef = storageRef.child("accommodation_images/\(imageID).jpg")

            dispatchGroup.enter()
            imageRef.putData(imageData, metadata: nil) { _, error in
                guard error == nil else {
                    dispatchGroup.leave()
                    return
                }
                imageRef.downloadURL { url, _ in
                    if let urlString = url?.absoluteString {
                        imageUrls.append(urlString)
                    }
                    dispatchGroup.leave()
                }
            }
        }

        dispatchGroup.notify(queue: .main) {
            let userRef = Firestore.firestore().collection("users").document(hostId)
            userRef.getDocument { [weak self] snapshot, error in
                guard let self = self else { return }
                guard let data = snapshot?.data(), let accommodationId = data["accommodationId"] as? String else {
                    print("accommodationId 불러오기 실패")
                    self.editView.hideLoading()
                    return
                }

                let accommodationRef = Firestore.firestore().collection("accommodations").document(accommodationId)
                accommodationRef.setData([
                    "name": name,
                    "location": address,
                    "description": description,
                    "hostId": hostId,
                    "imageURLs": imageUrls,
                    "amenities": Array(selectedAmenities),
                    "updatedAt": FieldValue.serverTimestamp()
                ], merge: true) { error in
                    if let error = error {
                        print("숙소 수정 실패: \(error)")
                        self.editView.hideLoading()
                    } else {
                        print("숙소 수정 완료")
                        let alert = UIAlertController(title: "성공", message: "숙소가 수정되었습니다.", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "확인", style: .default) { _ in
                            self.editView.hideLoading()
                            if let sceneDelegate = UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate {
                                let hostTabBar = HostMainTabBarController()
                                sceneDelegate.window?.rootViewController = hostTabBar
                                sceneDelegate.window?.makeKeyAndVisible()
                            }
                        })
                        self.present(alert, animated: true)
                    }
                }
            }
        }
    }
    
    deinit {
      
    }

    @objc private func toggleAmenity(_ sender: UIButton) {
        guard let amenity = sender.title(for: .normal) else { return }
        if editView.selectedAmenities.contains(amenity) {
            editView.selectedAmenities.remove(amenity)
            sender.backgroundColor = .clear
        } else {
            editView.selectedAmenities.insert(amenity)
            sender.backgroundColor = UIColor(red: 47/255, green: 175/255, blue: 83/255, alpha: 0.2)
        }
    }

    @objc private func selectImageTapped() {
        if editView.selectedImages.count >= 10 {
            let alert = UIAlertController(title: "알림", message: "사진은 최대 10장까지 등록 가능합니다.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "확인", style: .default))
            present(alert, animated: true)
            return
        }

        var config = PHPickerConfiguration()
        config.selectionLimit = 10 - editView.selectedImages.count
        config.filter = .images
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }

    private func deleteImage(_ index: Int) {
        guard index < editView.selectedImages.count else { return }
        editView.selectedImages.remove(at: index)
        editView.collectionView.reloadData()
        editView.photoCountLabel.text = "\(editView.selectedImages.count) / 10"
    }
}

extension EditAccommodationViewController: PHPickerViewControllerDelegate {
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
                        if self.editView.selectedImages.count < 10 {
                            self.editView.selectedImages.append(image)
                        }
                    }
                }
            }
        }
        group.notify(queue: .main) { [weak self] in
            guard let self = self else { return }
            self.editView.collectionView.reloadData()
            self.editView.photoCountLabel.text = "\(self.editView.selectedImages.count) / 10"
        }
    }
}

extension EditAccommodationViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return editView.selectedImages.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath)
        cell.contentView.subviews.forEach { $0.removeFromSuperview() }

        let imageView = UIImageView(image: editView.selectedImages[indexPath.item])
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
}
