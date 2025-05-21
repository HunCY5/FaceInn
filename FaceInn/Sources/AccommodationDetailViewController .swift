//
//  AccommodationDetailViewController .swift
//  FaceInn
//
//  Created by 신찬솔 on 5/20/25.
//

import UIKit
import Kingfisher
import FirebaseFirestore

final class AccommodationDetailViewController: UIViewController, UICollectionViewDataSource {

    // 예약 버튼 탭 클로저 타입 명시
    private var onReserveButtonTapped: ((AccommodationRoom) -> Void)?

    private let scrollView = UIScrollView()
    private let contentView = UIView()

    private let roomCardsStackView = UIStackView()

    var accommodation: Accommodation?

    private static var lastDisplayedRooms: [AccommodationRoom] = []
    private static var lastSelectedStartDate: Date?
    private static var lastSelectedEndDate: Date?
    private static var lastSelectedGuestCount: Int?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        self.hidesBottomBarWhenPushed = true
        self.title = accommodation?.name

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])

        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        layout.itemSize = CGSize(width: view.bounds.width, height: 250)

        let imageGallery = UICollectionView(frame: .zero, collectionViewLayout: layout)
        imageGallery.translatesAutoresizingMaskIntoConstraints = false
        imageGallery.isPagingEnabled = true
        imageGallery.backgroundColor = .white
        imageGallery.showsHorizontalScrollIndicator = false
        imageGallery.dataSource = self
        imageGallery.register(ImageCell.self, forCellWithReuseIdentifier: "ImageCell")
        contentView.addSubview(imageGallery)

        let titleLabel = UILabel()
        titleLabel.text = accommodation?.name ?? "숙소 이름"
        titleLabel.font = UIFont.boldSystemFont(ofSize: 22)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)

        let addressLabel = UILabel()
        addressLabel.text = accommodation?.location ?? "주소 정보 없음"
        addressLabel.font = UIFont.systemFont(ofSize: 16)
        addressLabel.textColor = .darkGray
        addressLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(addressLabel)

        let ratingLabel = UILabel()
        if let rating = accommodation?.rating, let reviewCount = accommodation?.reviewCount {
            ratingLabel.text = "⭐️ \(rating) (\(reviewCount)개 평가)"
        } else {
            ratingLabel.text = "⭐️ 평가 정보 없음"
        }
        ratingLabel.font = UIFont.systemFont(ofSize: 15)
        ratingLabel.textColor = .darkGray
        ratingLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(ratingLabel)

        let separator = UIView()
        separator.backgroundColor = .lightGray
        separator.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(separator)

        let amenitiesTitleLabel = UILabel()
        amenitiesTitleLabel.text = "편의시설"
        amenitiesTitleLabel.font = UIFont.boldSystemFont(ofSize: 18)
        amenitiesTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(amenitiesTitleLabel)

        let amenitiesStackView = UIStackView()
        amenitiesStackView.axis = .vertical
        amenitiesStackView.spacing = 6
        amenitiesStackView.translatesAutoresizingMaskIntoConstraints = false

        if let amenities = accommodation?.amenities {
            for item in amenities {
                let label = UILabel()
                label.text = "• \(item)"
                label.font = UIFont.systemFont(ofSize: 15)
                label.textColor = .darkGray
                amenitiesStackView.addArrangedSubview(label)
            }
        }

        contentView.addSubview(amenitiesStackView)

        let amenitiesBottomSeparator = UIView()
        amenitiesBottomSeparator.backgroundColor = .lightGray
        amenitiesBottomSeparator.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(amenitiesBottomSeparator)

        let bottomSeparator = UIView()
        bottomSeparator.backgroundColor = .lightGray
        bottomSeparator.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(bottomSeparator)

        let dateButton = UIButton(type: .system)
        dateButton.setTitle("📅 날짜 선택", for: .normal)
        dateButton.contentHorizontalAlignment = .center
        dateButton.tintColor = .black
        dateButton.layer.cornerRadius = 8
        dateButton.layer.borderWidth = 1
        dateButton.layer.borderColor = UIColor(red: 47/255, green: 175/255, blue: 83/255, alpha: 1).cgColor
        dateButton.backgroundColor = .white
        dateButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        dateButton.contentEdgeInsets = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        dateButton.translatesAutoresizingMaskIntoConstraints = false
        dateButton.addTarget(self, action: #selector(dateButtonTapped(_:)), for: .touchUpInside)
        contentView.addSubview(dateButton)

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M월 d일"
        if let start = UserDefaults.standard.object(forKey: "selectedStartDate") as? Date,
           let end = UserDefaults.standard.object(forKey: "selectedEndDate") as? Date {
            let title = "📅 \(formatter.string(from: start)) - \(formatter.string(from: end))"
            dateButton.setTitle(title, for: .normal)
        }

        let guestButton = UIButton(type: .system)
        guestButton.setTitle("👥 인원 선택", for: .normal)
        guestButton.contentHorizontalAlignment = .center
        guestButton.tintColor = .black
        guestButton.layer.cornerRadius = 8
        guestButton.layer.borderWidth = 1
        guestButton.layer.borderColor = UIColor(red: 47/255, green: 175/255, blue: 83/255, alpha: 1).cgColor
        guestButton.backgroundColor = .white
        guestButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        guestButton.contentEdgeInsets = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        guestButton.translatesAutoresizingMaskIntoConstraints = false
        guestButton.addTarget(self, action: #selector(guestButtonTapped(_:)), for: .touchUpInside)
        contentView.addSubview(guestButton)

        let savedGuestCount = UserDefaults.standard.object(forKey: "selectedGuestCount") != nil ?
            UserDefaults.standard.integer(forKey: "selectedGuestCount") : 2
        guestButton.setTitle("👥 \(savedGuestCount)명", for: .normal)

        NSLayoutConstraint.activate([
            imageGallery.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageGallery.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageGallery.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageGallery.heightAnchor.constraint(equalToConstant: 250),

            titleLabel.topAnchor.constraint(equalTo: imageGallery.bottomAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            addressLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            addressLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            addressLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),

            ratingLabel.topAnchor.constraint(equalTo: addressLabel.bottomAnchor, constant: 8),
            ratingLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            ratingLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),

            separator.topAnchor.constraint(equalTo: ratingLabel.bottomAnchor, constant: 20),
            separator.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            separator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            separator.heightAnchor.constraint(equalToConstant: 1),

            amenitiesTitleLabel.topAnchor.constraint(equalTo: separator.bottomAnchor, constant: 12),
            amenitiesTitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            amenitiesTitleLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),

            amenitiesStackView.topAnchor.constraint(equalTo: amenitiesTitleLabel.bottomAnchor, constant: 8),
            amenitiesStackView.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            amenitiesStackView.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),

            amenitiesBottomSeparator.topAnchor.constraint(equalTo: amenitiesStackView.bottomAnchor, constant: 16),
            amenitiesBottomSeparator.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            amenitiesBottomSeparator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            amenitiesBottomSeparator.heightAnchor.constraint(equalToConstant: 1)
        ])

        NSLayoutConstraint.activate([
            dateButton.topAnchor.constraint(equalTo: amenitiesBottomSeparator.bottomAnchor, constant: 20),
            dateButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            dateButton.widthAnchor.constraint(equalToConstant: 200),

            guestButton.topAnchor.constraint(equalTo: dateButton.topAnchor),
            guestButton.leadingAnchor.constraint(equalTo: dateButton.trailingAnchor, constant: 12),
            guestButton.widthAnchor.constraint(equalToConstant: 120)
        ])

        // Room cards stack view
        roomCardsStackView.axis = .vertical
        roomCardsStackView.spacing = 20
        roomCardsStackView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(roomCardsStackView)

        NSLayoutConstraint.activate([
            roomCardsStackView.topAnchor.constraint(equalTo: guestButton.bottomAnchor, constant: 20),
            roomCardsStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            roomCardsStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        ])

        // Load room cards
        reloadRoomCardsSafely()

        var lastBottomAnchor: NSLayoutYAxisAnchor = roomCardsStackView.bottomAnchor

        if let introduction = accommodation?.description {
            let introductionTitleLabel = UILabel()
            introductionTitleLabel.text = "숙소 소개"
            introductionTitleLabel.font = UIFont.boldSystemFont(ofSize: 18)
            introductionTitleLabel.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(introductionTitleLabel)

            let introductionLabel = UILabel()
            introductionLabel.text = introduction
            introductionLabel.font = UIFont.systemFont(ofSize: 15)
            introductionLabel.textColor = .darkGray
            introductionLabel.numberOfLines = 0
            introductionLabel.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(introductionLabel)

            NSLayoutConstraint.activate([
                introductionTitleLabel.topAnchor.constraint(equalTo: lastBottomAnchor, constant: 24),
                introductionTitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
                introductionTitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

                introductionLabel.topAnchor.constraint(equalTo: introductionTitleLabel.bottomAnchor, constant: 8),
                introductionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
                introductionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
            ])

            lastBottomAnchor = introductionLabel.bottomAnchor
        }

        NSLayoutConstraint.activate([
            bottomSeparator.topAnchor.constraint(equalTo: lastBottomAnchor, constant: 20),
            bottomSeparator.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            bottomSeparator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            bottomSeparator.heightAnchor.constraint(equalToConstant: 1)
        ])

        // 판매자 정보 버튼 추가
        let sellerInfoButton = UIButton(type: .system)
        sellerInfoButton.setTitle("판매자 정보", for: .normal)
        sellerInfoButton.setTitleColor(.black, for: .normal)
        sellerInfoButton.contentHorizontalAlignment = .left
        sellerInfoButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 0)
        sellerInfoButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        sellerInfoButton.backgroundColor = UIColor(red: 247/255, green: 248/255, blue: 250/255, alpha: 1)
        sellerInfoButton.layer.cornerRadius = 8
        sellerInfoButton.addTarget(self, action: #selector(sellerInfoTapped), for: .touchUpInside)
        sellerInfoButton.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(sellerInfoButton)

        let arrowImageView = UIImageView(image: UIImage(systemName: "chevron.right"))
        arrowImageView.tintColor = .lightGray
        arrowImageView.translatesAutoresizingMaskIntoConstraints = false
        sellerInfoButton.addSubview(arrowImageView)

        NSLayoutConstraint.activate([
            sellerInfoButton.topAnchor.constraint(equalTo: bottomSeparator.bottomAnchor, constant: 16),
            sellerInfoButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            sellerInfoButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            sellerInfoButton.heightAnchor.constraint(equalToConstant: 60),

            arrowImageView.centerYAnchor.constraint(equalTo: sellerInfoButton.centerYAnchor),
            arrowImageView.trailingAnchor.constraint(equalTo: sellerInfoButton.trailingAnchor, constant: -16),
            arrowImageView.widthAnchor.constraint(equalToConstant: 12),
            arrowImageView.heightAnchor.constraint(equalToConstant: 20),

            sellerInfoButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -30)
        ])
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return accommodation?.imageURLs?.count ?? 0
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageCell", for: indexPath) as? ImageCell else {
            return UICollectionViewCell()
        }

        if let urlString = accommodation?.imageURLs?[indexPath.item], let url = URL(string: urlString) {
            cell.configure(with: url)
        }

        return cell
    }
    
    @objc private func dateButtonTapped(_ sender: UIButton) {
        let vc = DatePickerPopoverViewController()
        vc.modalPresentationStyle = .automatic
        if let sheet = vc.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
        }
        vc.onDateSelected = { [weak self, weak sender] startDate, endDate in
            guard let self = self else { return }
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "ko_KR")
            formatter.dateFormat = "M월 d일"
            if let start = startDate, let end = endDate {
                let title = "📅 \(formatter.string(from: start)) - \(formatter.string(from: end))"
                sender?.setTitle(title, for: .normal)
                UserDefaults.standard.set(start, forKey: "selectedStartDate")
                UserDefaults.standard.set(end, forKey: "selectedEndDate")
            } else if let start = startDate {
                let title = "📅 \(formatter.string(from: start))"
                sender?.setTitle(title, for: .normal)
                UserDefaults.standard.set(start, forKey: "selectedStartDate")
                UserDefaults.standard.removeObject(forKey: "selectedEndDate")
            }
            self.reloadRoomCardsSafely()
        }
        present(vc, animated: true)
    }

    @objc private func guestButtonTapped(_ sender: UIButton) {
        let vc = GuestSelectorViewController()
        vc.modalPresentationStyle = .automatic
        if let sheet = vc.sheetPresentationController {
            sheet.detents = [.custom(resolver: { _ in return 130 })]
            sheet.prefersGrabberVisible = true
        }
        vc.onGuestsSelected = { [weak self, weak sender] adults, children in
            guard let self else { return }
            let totalGuests = adults + children
            sender?.setTitle("👥 \(totalGuests)명", for: .normal)
            UserDefaults.standard.set(adults, forKey: "selectedAdults")
            UserDefaults.standard.set(children, forKey: "selectedChildren")
            UserDefaults.standard.set(totalGuests, forKey: "selectedGuestCount")
            
            DispatchQueue.main.async {
                self.reloadRoomCardsSafely()
            }
        }
        present(vc, animated: true)
    }

    private func reloadRoomCardsSafely() {
        roomCardsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        let guestCount = UserDefaults.standard.object(forKey: "selectedGuestCount") != nil
            ? UserDefaults.standard.integer(forKey: "selectedGuestCount")
            : 2

        let startDate = UserDefaults.standard.object(forKey: "selectedStartDate") as? Date ?? Date()
        let endDate = UserDefaults.standard.object(forKey: "selectedEndDate") as? Date ?? Calendar.current.date(byAdding: .day, value: 1, to: startDate)!

        let numberOfNights = Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 1

        guard let rooms = accommodation?.rooms else { return }

        var availableRooms: [AccommodationRoom] = []
        var unavailableRooms: [AccommodationRoom] = []

        for roomDict in rooms {
            if let id = roomDict["id"] as? String,
               let name = roomDict["name"] as? String,
               let description = roomDict["description"] as? String,
               let price = roomDict["price"] as? Int,
               let maxOccupancy = roomDict["maxOccupancy"] as? Int,
               let imageURLs = roomDict["imageURLs"] as? [String],
               let checkInTime = roomDict["checkInTime"] as? String,
               let checkOutTime = roomDict["checkOutTime"] as? String,
               let amenities = roomDict["amenities"] as? [String] {

                let room = AccommodationRoom(
                    id: id,
                    name: name,
                    description: description,
                    price: price,
                    maxOccupancy: maxOccupancy,
                    imageURLs: imageURLs,
                    checkInTime: checkInTime,
                    checkOutTime: checkOutTime,
                    amenities: amenities
                )

                if guestCount <= maxOccupancy {
                    availableRooms.append(room)
                } else {
                    unavailableRooms.append(room)
                }
            }
        }

        availableRooms.sort { $0.price < $1.price }
        let sortedRooms = availableRooms + unavailableRooms

        for (index, room) in sortedRooms.enumerated() {
            let roomCard = RoomCardView(room: room, numberOfNights: numberOfNights)
            roomCard.translatesAutoresizingMaskIntoConstraints = false
            roomCard.updateGuestCount(guestCount)
            roomCard.alpha = 0
            roomCard.transform = CGAffineTransform(translationX: 0, y: 20)

            roomCard.onReserveButtonTapped = { [weak self] room in
                guard let self = self, let accommodation = self.accommodation else { return }

                let reservationVC = ReservationViewController()
                reservationVC.accommodation = accommodation
                reservationVC.room = room
                reservationVC.startDate = startDate
                reservationVC.endDate = endDate
                reservationVC.guestCount = guestCount

                self.navigationController?.pushViewController(reservationVC, animated: true)
            }

            roomCardsStackView.addArrangedSubview(roomCard)

            UIView.animate(withDuration: 0.3, delay: 0.05 * Double(index), options: [.curveEaseOut], animations: {
                roomCard.alpha = 1
                roomCard.transform = .identity
            }, completion: nil)
        }

        if sortedRooms.isEmpty {
            let label = UILabel()
            label.text = "조건에 맞는 객실이 없습니다"
            label.textAlignment = .center
            label.textColor = .gray
            roomCardsStackView.addArrangedSubview(label)
        }
    }
}

final class ImageCell: UICollectionViewCell {
    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with url: URL) {
        imageView.kf.setImage(with: url)
    }
}

extension AccommodationDetailViewController: UIPopoverPresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
    @objc private func sellerInfoTapped() {
        let vc = HostProfileViewController()
        vc.hostId = self.accommodation?.hostId ?? ""
        navigationController?.pushViewController(vc, animated: true)
    }
}
