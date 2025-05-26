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

final class ReservationViewController: UIViewController {
    
    var accommodation: Accommodation?
    var room: AccommodationRoom?
    var startDate: Date?
    var endDate: Date?
    var guestCount: Int?
    
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
        let nameField = UITextField()
        nameField.borderStyle = .roundedRect
        nameField.placeholder = "이름"
        let phoneField = UITextField()
        phoneField.borderStyle = .roundedRect
        phoneField.placeholder = "휴대폰 번호"
        phoneField.keyboardType = .phonePad
        // Firebase Firestore에서 사용자 정보 불러오기
        if let user = Auth.auth().currentUser {
            let db = Firestore.firestore()
            let userRef = db.collection("users").document(user.uid)
            userRef.getDocument { document, error in
                if let document = document, document.exists {
                    let data = document.data()
                    nameField.text = data?["name"] as? String
                    phoneField.text = data?["phoneNumber"] as? String
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
        let payButton = UIButton(type: .system)
        payButton.setTitle("\(totalPrice.formattedWithSeparator)원 결제하기", for: .normal)
        payButton.backgroundColor = UIColor(red: 47/255, green: 175/255, blue: 83/255, alpha: 1.0)
        payButton.setTitleColor(.white, for: .normal)
        payButton.titleLabel?.font = .boldSystemFont(ofSize: 16)
        payButton.layer.cornerRadius = 8
        payButton.translatesAutoresizingMaskIntoConstraints = false
        payButton.heightAnchor.constraint(equalToConstant: 44).isActive = true


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
        mainStack.addArrangedSubview(totalPaymentStack)
        mainStack.addArrangedSubview(payButton)

        view.addSubview(mainStack)

        NSLayoutConstraint.activate([
            mainStack.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 24),
            mainStack.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -24),
            mainStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
        ])
    }
}

private extension Int {
    var formattedWithSeparator: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }
}
