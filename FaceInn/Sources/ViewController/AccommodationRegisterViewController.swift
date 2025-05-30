//
//  AccommodationRegisterViewController.swift
//  FaceInn
//
//  Created by 신찬솔 on 5/30/25.
//

import UIKit
import PhotosUI
import FirebaseFirestore
import FirebaseStorage
import FirebaseAuth

class AccommodationRegisterViewController: UIViewController {

    private let registerView = AccommodationRegisterView()

    override func loadView() {
        self.view = registerView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "숙소 등록"
        registerView.collectionView.dataSource = self
        registerView.collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "Cell")
        registerView.selectImageButton.addTarget(self, action: #selector(selectImageTapped), for: .touchUpInside)
        registerView.registerButton.addTarget(self, action: #selector(registerAccommodation), for: .touchUpInside)
        
        registerView.logoutButton.addTarget(self, action: #selector(self.didTapLogout), for: .touchUpInside)
        
        registerView.amenityButtonHandler = { [weak self] sender in
            guard let self = self else { return }
            self.toggleAmenity(sender)
        }
        registerView.deleteImageHandler = { [weak self] index in
            self?.deleteImage(index)
        }
    }

    @objc private func registerAccommodation() {
        let confirmationAlert = UIAlertController(title: "확인", message: "숙소를 등록하시겠습니까?", preferredStyle: .alert)
        confirmationAlert.addAction(UIAlertAction(title: "취소", style: .cancel, handler: nil))
        confirmationAlert.addAction(UIAlertAction(title: "등록", style: .default, handler: { _ in
            self.performAccommodationRegistration()
        }))
        present(confirmationAlert, animated: true)
        return
    }
    
    private func performAccommodationRegistration() {
        let selectedImages = registerView.selectedImages
        let selectedAmenities = registerView.selectedAmenities
        guard !selectedImages.isEmpty else {
            let alert = UIAlertController(title: "오류", message: "최소 한 장 이상의 사진을 등록해주세요.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "확인", style: .default))
            present(alert, animated: true)
            return
        }
        guard !selectedAmenities.isEmpty else {
            let alert = UIAlertController(title: "오류", message: "최소 하나 이상의 편의시설을 선택해주세요.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "확인", style: .default))
            present(alert, animated: true)
            return
        }
        guard let name = registerView.nameTextField.text, !name.isEmpty,
              let address = registerView.addressTextField.text, !address.isEmpty,
              let description = registerView.descriptionTextField.text, !description.isEmpty else {
            let alert = UIAlertController(title: "오류", message: "모든 숙소 정보를 입력해주세요.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "확인", style: .default))
            present(alert, animated: true)
            return
        }

        guard let hostId = Auth.auth().currentUser?.uid else {
            print("로그인된 사용자 정보 없음")
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
            let data: [String: Any] = [
                "name": name,
                "location": address,
                "description": description,
                "hostId": hostId,
                "imageURLs": imageUrls,
                "amenities": Array(selectedAmenities),
                "createdAt": FieldValue.serverTimestamp()
            ]

            let collectionRef = Firestore.firestore().collection("accommodations")
            var newDocumentRef: DocumentReference? = nil
            newDocumentRef = collectionRef.addDocument(data: data) { [weak self] error in
                guard let self = self else { return }
                if let error = error {
                    print("숙소 저장 실패: \(error)")
                } else if let documentID = newDocumentRef?.documentID {
                    Firestore.firestore().collection("users").document(hostId).updateData([
                        "accommodationId": documentID
                    ]) { error in
                        if let error = error {
                            print("사용자 문서 업데이트 실패: \(error)")
                        } else {
                            print("사용자 문서에 accommodationId 업데이트 완료")
                        }
                    }

                    let alert = UIAlertController(title: "성공", message: "숙소가 등록되었습니다.", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "확인", style: .default) { _ in
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
    
    deinit {
        // AccommodationRegisterView에서 keyboard notification 해제됨
    }

    @objc private func toggleAmenity(_ sender: UIButton) {
        guard let amenity = sender.title(for: .normal) else { return }
        if registerView.selectedAmenities.contains(amenity) {
            registerView.selectedAmenities.remove(amenity)
            sender.backgroundColor = .clear
        } else {
            registerView.selectedAmenities.insert(amenity)
            sender.backgroundColor = UIColor(red: 47/255, green: 175/255, blue: 83/255, alpha: 0.2)
        }
    }

    @objc private func selectImageTapped() {
        if registerView.selectedImages.count >= 10 {
            let alert = UIAlertController(title: "알림", message: "사진은 최대 10장까지 등록 가능합니다.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "확인", style: .default))
            present(alert, animated: true)
            return
        }

        var config = PHPickerConfiguration()
        config.selectionLimit = 10 - registerView.selectedImages.count
        config.filter = .images
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }

    private func deleteImage(_ index: Int) {
        guard index < registerView.selectedImages.count else { return }
        registerView.selectedImages.remove(at: index)
        registerView.collectionView.reloadData()
        registerView.photoCountLabel.text = "\(registerView.selectedImages.count) / 10"
    }
}

extension AccommodationRegisterViewController: PHPickerViewControllerDelegate {
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
                        if self.registerView.selectedImages.count < 10 {
                            self.registerView.selectedImages.append(image)
                        }
                    }
                }
            }
        }
        group.notify(queue: .main) { [weak self] in
            guard let self = self else { return }
            self.registerView.collectionView.reloadData()
            self.registerView.photoCountLabel.text = "\(self.registerView.selectedImages.count) / 10"
        }
    }
}

extension AccommodationRegisterViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return registerView.selectedImages.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath)
        cell.contentView.subviews.forEach { $0.removeFromSuperview() }

        let imageView = UIImageView(image: registerView.selectedImages[indexPath.item])
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
    @objc private func didTapLogout() {
        // Sign out from Firebase
        do {
            try Auth.auth().signOut()
        } catch {
            print("Sign out failed: \(error)")
        }

        // userdafualt 초기화
        UserDefaults.standard.set("guest", forKey: "userType")

        // 루트뷰 변경: MainTabBarController
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let sceneDelegate = windowScene.delegate as? SceneDelegate,
           let window = sceneDelegate.window {
            window.rootViewController = MainTabBarController()
            window.makeKeyAndVisible()
        }
    }
}
