// 얼굴 등록 완료 델리게이트 프로토콜
protocol FaceCaptureDelegate: AnyObject {
    func faceCaptureDidFinish()
}
//
//  ReservationViewController.swift
//  FaceInn
//
//  Created by 신찬솔 on 5/21/25.
//


import UIKit
import Kingfisher
import FirebaseAuth
import FirebaseFirestore

final class ReservationViewController: UIViewController, UITextFieldDelegate {
    
    var accommodation: Accommodation?
    var room: AccommodationRoom?
    var startDate: Date?
    var endDate: Date?
    var guestCount: Int?

    private let nameField = UITextField()
    private let phoneField = UITextField()
    private let payButton = UIButton(type: .system)
    // 얼굴인식 체크박스 관련
    private let faceIdSwitch = UISwitch()
    private let faceIdLabel = UILabel()
    private var faceIdAvailable = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        title = "예약"

        guard let accommodation = accommodation,
              let room = room,
              let startDate = UserDefaults.standard.object(forKey: "selectedStartDate") as? Date,
              let endDate = UserDefaults.standard.object(forKey: "selectedEndDate") as? Date else {
            return
        }

        let calendar = Calendar.current
        let numberOfNights = calendar.dateComponents([.day], from: startDate, to: endDate).day ?? 1
        let totalPrice = room.price * numberOfNights
        let guestCount = UserDefaults.standard.integer(forKey: "selectedGuestCount")

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy.MM.dd"
        let checkInDateStr = formatter.string(from: startDate)
        let checkOutDateStr = formatter.string(from: endDate)

        // 1. Hotel name label (bold)
        let hotelNameLabel = UILabel()
        hotelNameLabel.font = .systemFont(ofSize: 20, weight: .bold)
        hotelNameLabel.text = accommodation.name
        hotelNameLabel.translatesAutoresizingMaskIntoConstraints = false

        // 2. Room name label
        let roomNameLabel = UILabel()
        roomNameLabel.font = .systemFont(ofSize: 16)
        roomNameLabel.text = room.name
        roomNameLabel.translatesAutoresizingMaskIntoConstraints = false

        // 3. Guest capacity label
        let guestCapacityLabel = UILabel()
        guestCapacityLabel.font = .systemFont(ofSize: 14)
        guestCapacityLabel.text = "숙박인원 \(guestCount)인, 최대 \(room.maxOccupancy)인"
        guestCapacityLabel.textColor = .gray
        guestCapacityLabel.translatesAutoresizingMaskIntoConstraints = false

        // 4. Horizontal stack for check-in, nights, check-out
        let checkInTitleLabel = UILabel()
        checkInTitleLabel.font = .systemFont(ofSize: 14, weight: .medium)
        checkInTitleLabel.text = "체크인"
        checkInTitleLabel.translatesAutoresizingMaskIntoConstraints = false

        let checkInDateLabel = UILabel()
        checkInDateLabel.font = .systemFont(ofSize: 14)
        checkInDateLabel.text = "\(checkInDateStr)\n15:00"
        checkInDateLabel.numberOfLines = 2
        checkInDateLabel.translatesAutoresizingMaskIntoConstraints = false

        let checkInStack = UIStackView(arrangedSubviews: [checkInTitleLabel, checkInDateLabel])
        checkInStack.axis = .vertical
        checkInStack.alignment = .center
        checkInStack.spacing = 4
        checkInStack.translatesAutoresizingMaskIntoConstraints = false


        let checkOutTitleLabel = UILabel()
        checkOutTitleLabel.font = .systemFont(ofSize: 14, weight: .medium)
        checkOutTitleLabel.text = "체크아웃"
        checkOutTitleLabel.translatesAutoresizingMaskIntoConstraints = false

        let checkOutDateLabel = UILabel()
        checkOutDateLabel.font = .systemFont(ofSize: 14)
        checkOutDateLabel.text = "\(checkOutDateStr)\n11:00"
        checkOutDateLabel.numberOfLines = 2
        checkOutDateLabel.translatesAutoresizingMaskIntoConstraints = false

        let checkOutStack = UIStackView(arrangedSubviews: [checkOutTitleLabel, checkOutDateLabel])
        checkOutStack.axis = .vertical
        checkOutStack.alignment = .center
        checkOutStack.spacing = 4
        checkOutStack.translatesAutoresizingMaskIntoConstraints = false

        // --- Segmented check-in/out container ---
        let checkInOutContainer = UIView()
        checkInOutContainer.backgroundColor = UIColor(white: 0.97, alpha: 1.0)
        checkInOutContainer.layer.cornerRadius = 12
        checkInOutContainer.translatesAutoresizingMaskIntoConstraints = false

        let verticalDivider = UIView()
        verticalDivider.backgroundColor = UIColor(white: 0.9, alpha: 1.0)
        verticalDivider.translatesAutoresizingMaskIntoConstraints = false

        let nightsBadge = UILabel()
        nightsBadge.text = "\(numberOfNights)박"
        nightsBadge.font = .boldSystemFont(ofSize: 13)
        nightsBadge.textColor = .black
        nightsBadge.backgroundColor = .white
        nightsBadge.textAlignment = .center
        nightsBadge.layer.cornerRadius = 12
        nightsBadge.clipsToBounds = true
        nightsBadge.translatesAutoresizingMaskIntoConstraints = false

        checkInOutContainer.addSubview(checkInStack)
        checkInOutContainer.addSubview(checkOutStack)
        checkInOutContainer.addSubview(verticalDivider)
        checkInOutContainer.addSubview(nightsBadge)

        NSLayoutConstraint.activate([
            checkInStack.topAnchor.constraint(equalTo: checkInOutContainer.topAnchor, constant: 16),
            checkInStack.leadingAnchor.constraint(equalTo: checkInOutContainer.leadingAnchor, constant: 16),
            checkInStack.bottomAnchor.constraint(equalTo: checkInOutContainer.bottomAnchor, constant: -16),
            checkInStack.trailingAnchor.constraint(equalTo: verticalDivider.leadingAnchor, constant: -8),

            verticalDivider.centerXAnchor.constraint(equalTo: checkInOutContainer.centerXAnchor),
            verticalDivider.widthAnchor.constraint(equalToConstant: 1),
            verticalDivider.topAnchor.constraint(equalTo: checkInOutContainer.topAnchor, constant: 12),
            verticalDivider.bottomAnchor.constraint(equalTo: checkInOutContainer.bottomAnchor, constant: -12),

            checkOutStack.topAnchor.constraint(equalTo: checkInOutContainer.topAnchor, constant: 16),
            checkOutStack.trailingAnchor.constraint(equalTo: checkInOutContainer.trailingAnchor, constant: -16),
            checkOutStack.bottomAnchor.constraint(equalTo: checkInOutContainer.bottomAnchor, constant: -16),
            checkOutStack.leadingAnchor.constraint(equalTo: verticalDivider.trailingAnchor, constant: 8),

            nightsBadge.centerXAnchor.constraint(equalTo: checkInOutContainer.centerXAnchor),
            nightsBadge.centerYAnchor.constraint(equalTo: checkInOutContainer.centerYAnchor),
            nightsBadge.widthAnchor.constraint(equalToConstant: 36),
            nightsBadge.heightAnchor.constraint(equalToConstant: 24)
        ])

        // 5. "예약자 정보" label
        let reservationInfoLabel = UILabel()
        reservationInfoLabel.font = .systemFont(ofSize: 16, weight: .medium)
        reservationInfoLabel.text = "예약자 정보"
        reservationInfoLabel.translatesAutoresizingMaskIntoConstraints = false

        // 6. Name and phone text fields
        nameField.borderStyle = .roundedRect
        nameField.placeholder = "이름"
        phoneField.borderStyle = .roundedRect
        phoneField.placeholder = "휴대폰 번호"
        phoneField.keyboardType = .numberPad
        // 키보드 상단에 완료 버튼 툴바 추가
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneButton = UIBarButtonItem(title: "완료", style: .done, target: self, action: #selector(dismissKeyboard))
        toolbar.items = [flexSpace, doneButton]
        phoneField.inputAccessoryView = toolbar
        nameField.delegate = self
        phoneField.delegate = self
        // Firebase Firestore에서 사용자 정보 불러오기
        if let user = Auth.auth().currentUser {
            let db = Firestore.firestore()
            let userRef = db.collection("users").document(user.uid)
            userRef.getDocument { [weak self] document, error in
                guard let self = self else { return }
                if let document = document, document.exists {
                    let data = document.data()
                    self.nameField.text = data?["name"] as? String
                    self.phoneField.text = data?["phoneNumber"] as? String
                    // 얼굴 벡터 유무로 얼굴인식 체크박스 활성화
                    let front = data?["front_vector"]
                    let left = data?["left_vector"]
                    let right = data?["right_vector"]
                    self.faceIdAvailable = front != nil || left != nil || right != nil
                    self.faceIdSwitch.setOn(self.faceIdAvailable, animated: false)
                    self.updatePayButtonState()
                } else {
                    print("사용자 문서를 찾을 수 없습니다: \(error?.localizedDescription ?? "알 수 없는 오류")")
                }
            }
        }
        nameField.translatesAutoresizingMaskIntoConstraints = false
        phoneField.translatesAutoresizingMaskIntoConstraints = false


        // 8. "총 결제 금액" label with red price
        let totalPaymentTitleLabel = UILabel()
        totalPaymentTitleLabel.font = .systemFont(ofSize: 16, weight: .medium)
        totalPaymentTitleLabel.text = "총 결제 금액"
        totalPaymentTitleLabel.translatesAutoresizingMaskIntoConstraints = false

        let totalPriceLabel = UILabel()
        totalPriceLabel.font = .boldSystemFont(ofSize: 18)
        totalPriceLabel.textColor = .red
        totalPriceLabel.text = "\(totalPrice.formattedWithSeparator)원"
        totalPriceLabel.translatesAutoresizingMaskIntoConstraints = false

        // 9. Payment button
        payButton.setTitle("\(totalPrice.formattedWithSeparator)원 결제하기", for: .normal)
        payButton.backgroundColor = UIColor(red: 47/255, green: 175/255, blue: 83/255, alpha: 1.0)
        payButton.setTitleColor(.white, for: .normal)
        payButton.titleLabel?.font = .boldSystemFont(ofSize: 16)
        payButton.layer.cornerRadius = 8
        payButton.translatesAutoresizingMaskIntoConstraints = false
        payButton.heightAnchor.constraint(equalToConstant: 44).isActive = true
        payButton.addTarget(self, action: #selector(saveReservationToFirestore), for: .touchUpInside)
        // Add text field target actions for validation
        nameField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        phoneField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        updatePayButtonState()



        // Stack for total payment title and price
        let totalPaymentStack = UIStackView(arrangedSubviews: [totalPaymentTitleLabel, totalPriceLabel])
        totalPaymentStack.axis = .vertical
        totalPaymentStack.spacing = 4
        totalPaymentStack.translatesAutoresizingMaskIntoConstraints = false

        // Main vertical stack
        let mainStack = UIStackView()
        mainStack.axis = .vertical
        mainStack.spacing = 16
        mainStack.alignment = .fill
        mainStack.translatesAutoresizingMaskIntoConstraints = false

        // Add hotel name
        mainStack.addArrangedSubview(hotelNameLabel)
        // Group room name and guest capacity with custom spacing
        let roomInfoStack = UIStackView(arrangedSubviews: [roomNameLabel, guestCapacityLabel])
        roomInfoStack.axis = .vertical
        roomInfoStack.spacing = 2
        roomInfoStack.translatesAutoresizingMaskIntoConstraints = false
        mainStack.addArrangedSubview(roomInfoStack)

        // Room image scroll view
        let imageScrollView = UIScrollView()
        imageScrollView.showsHorizontalScrollIndicator = false
        imageScrollView.isPagingEnabled = true
        imageScrollView.translatesAutoresizingMaskIntoConstraints = false
        imageScrollView.heightAnchor.constraint(equalToConstant: 200).isActive = true

        let imageStackView = UIStackView()
        imageStackView.axis = .horizontal
        imageStackView.spacing = 8
        imageStackView.translatesAutoresizingMaskIntoConstraints = false

        imageScrollView.addSubview(imageStackView)

        NSLayoutConstraint.activate([
            imageStackView.topAnchor.constraint(equalTo: imageScrollView.topAnchor),
            imageStackView.bottomAnchor.constraint(equalTo: imageScrollView.bottomAnchor),
            imageStackView.leadingAnchor.constraint(equalTo: imageScrollView.leadingAnchor),
            imageStackView.trailingAnchor.constraint(equalTo: imageScrollView.trailingAnchor),
            imageStackView.heightAnchor.constraint(equalTo: imageScrollView.heightAnchor)
        ])

        let imageURLs = room.imageURLs
        for urlString in imageURLs {
            if let url = URL(string: urlString) {
                let imageView = UIImageView()
                imageView.contentMode = .scaleAspectFill
                imageView.clipsToBounds = true
                imageView.layer.cornerRadius = 8
                imageView.translatesAutoresizingMaskIntoConstraints = false
                imageView.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.width - 60).isActive = true

                // Load image using Kingfisher
                imageView.kf.setImage(with: url)

                imageStackView.addArrangedSubview(imageView)
            }
        }

        mainStack.addArrangedSubview(imageScrollView)

        // Continue adding the rest
        mainStack.addArrangedSubview(checkInOutContainer)
        mainStack.addArrangedSubview(reservationInfoLabel)
        mainStack.addArrangedSubview(nameField)
        mainStack.addArrangedSubview(phoneField)
        // 얼굴인식 체크박스 UI 추가
        faceIdLabel.text = "얼굴인식으로 체크인"
        faceIdLabel.font = .systemFont(ofSize: 14)
        faceIdLabel.translatesAutoresizingMaskIntoConstraints = false
        faceIdSwitch.translatesAutoresizingMaskIntoConstraints = false
        // 얼굴인식 스위치 값 변경 감지 액션 추가
        faceIdSwitch.addTarget(self, action: #selector(handleFaceIdSwitchChanged), for: .valueChanged)
        let faceIdStack = UIStackView(arrangedSubviews: [faceIdLabel, faceIdSwitch])
        faceIdStack.axis = .horizontal
        faceIdStack.spacing = 8
        faceIdStack.alignment = .center
        faceIdStack.translatesAutoresizingMaskIntoConstraints = false
        mainStack.addArrangedSubview(faceIdStack)
        mainStack.addArrangedSubview(totalPaymentStack)
        mainStack.addArrangedSubview(payButton)

        // MARK: - KeyboardAvoiding: UIScrollView 도입
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        let contentView = UIView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)

        contentView.addSubview(mainStack)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            mainStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 24),
            mainStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            mainStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            mainStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])

        // Add tap gesture to dismiss keyboard
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)

        // Keyboard notification observers
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc private func saveReservationToFirestore() {
        // 결제 버튼 중복 방지: 비활성화
        payButton.isEnabled = false

        guard let user = Auth.auth().currentUser,
              let accommodation = accommodation,
              let room = room,
              let startDate = startDate,
              let endDate = endDate else {
            print("예약 정보가 불완전합니다.")
            return
        }

        let guestCount = UserDefaults.standard.integer(forKey: "selectedGuestCount")
        let calendar = Calendar.current
        let numberOfNights = calendar.dateComponents([.day], from: startDate, to: endDate).day ?? 1
        let totalPrice = room.price * numberOfNights

        // Generate a unique 6-digit reservation number
        let reserveNumber = Int.random(in: 100000...999999)

        let reservationData: [String: Any] = [
            "userId": user.uid,
            "hostId": accommodation.hostId ?? "",
            "accommodationId": accommodation.id,
            "roomId": room.id,
            "roomName": room.name,
            "guestCount": guestCount,
            "startDate": Timestamp(date: startDate),
            "endDate": Timestamp(date: endDate),
            "totalPrice": totalPrice,
            "numberOfNights": numberOfNights,
            "createdAt": FieldValue.serverTimestamp(),
            "accommodationName": accommodation.name,
            "imageURL": room.imageURLs.first ?? "",
            "useFaceId": faceIdSwitch.isOn && faceIdAvailable,
            "checkIn": false,
            "reserveNumber": reserveNumber
        ]

        Firestore.firestore().collection("reserves").addDocument(data: reservationData) { error in
            if let error = error {
                print("예약 저장 실패: \(error.localizedDescription)")
                self.payButton.isEnabled = true
            } else {
                print("예약 저장 성공")
                // 예약 완료 알림 표시 및 탭바로 이동
                DispatchQueue.main.async {
                    let alert = UIAlertController(title: "예약 완료", message: "예약이 성공적으로 완료되었습니다.", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "확인", style: .default) { _ in
                        // 탭바 컨트롤러로 이동
                        let tabBarController = MainTabBarController()
                        tabBarController.selectedIndex = 2
                        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                           let sceneDelegate = windowScene.delegate as? UIWindowSceneDelegate,
                           let window = sceneDelegate.window {
                            window?.rootViewController = tabBarController
                            window?.makeKeyAndVisible()
                        }
                    })
                    self.present(alert, animated: true)
                }
            }
        }
    }

    @objc private func textFieldDidChange(_ textField: UITextField) {
        updatePayButtonState()
    }

    private func updatePayButtonState() {
        let isNameFilled = !(nameField.text?.isEmpty ?? true)
        let isPhoneFilled = !(phoneField.text?.isEmpty ?? true)
        payButton.isEnabled = isNameFilled && isPhoneFilled
        payButton.alpha = payButton.isEnabled ? 1.0 : 0.5
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    @objc private func handleFaceIdSwitchChanged(_ sender: UISwitch) {
        if sender.isOn && !faceIdAvailable {
            let alert = UIAlertController(title: "얼굴 정보 필요", message: "얼굴을 등록해주세요.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "취소", style: .cancel, handler: { _ in
                sender.setOn(false, animated: true)
            }))
            alert.addAction(UIAlertAction(title: "확인", style: .default, handler: { _ in
                let faceCaptureVC = FaceCaptureViewController()
                faceCaptureVC.delegate = self
                self.navigationController?.pushViewController(faceCaptureVC, animated: true)
            }))
            present(alert, animated: true)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.tabBar.isHidden = true

        if let user = Auth.auth().currentUser {
            let db = Firestore.firestore()
            let userRef = db.collection("users").document(user.uid)
            userRef.getDocument { [weak self] document, error in
                guard let self = self else { return }
                if let document = document, document.exists {
                    let data = document.data()
                    let front = data?["front_vector"]
                    let left = data?["left_vector"]
                    let right = data?["right_vector"]
                    self.faceIdAvailable = front != nil || left != nil || right != nil
                    if !self.faceIdAvailable {
                        self.faceIdSwitch.setOn(false, animated: false)
                    }
                }
            }
        }
    }
    // MARK: - Keyboard Handling
    @objc private func keyboardWillShow(notification: Notification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            if let scrollView = self.view.subviews.first(where: { $0 is UIScrollView }) as? UIScrollView {
                scrollView.contentInset.bottom = keyboardSize.height + 20
            }
        }
    }

    @objc private func keyboardWillHide(notification: Notification) {
        if let scrollView = self.view.subviews.first(where: { $0 is UIScrollView }) as? UIScrollView {
            scrollView.contentInset.bottom = 0
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// 얼굴 등록 완료 델리게이트 구현
extension ReservationViewController: FaceCaptureDelegate {
    func faceCaptureDidFinish() {
        self.faceIdAvailable = true
        self.faceIdSwitch.setOn(true, animated: true)
    }
}

private extension Int {
    var formattedWithSeparator: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }
}

