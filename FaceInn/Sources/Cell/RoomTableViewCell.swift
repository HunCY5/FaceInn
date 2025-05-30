//
//  RoomTableViewCell.swift
//  FaceInn
//
//  Created by 신찬솔 on 5/31/25.
//

import UIKit
import FirebaseFirestore

final class RoomTableViewCell: UITableViewCell {
    private var currentRoom: AccommodationRoom?
    private var currentHostId: String?
    private let containerView = UIView()
    private let nameLabel = UILabel()
    private let occupancyLabel = UILabel()
    private let priceLabel = UILabel()
    private let statusBadge = UILabel()
    private let editButton = UIButton(type: .system)
    private let contentStackView = UIStackView()
    private let occupancyPriceStackView = UIStackView()
    private let reservationInfoLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with room: AccommodationRoom, hostId: String) {
        currentRoom = room
        currentHostId = hostId
        nameLabel.text = room.name
        occupancyLabel.text = "👥 최대 \(room.maxOccupancy)명"
        priceLabel.text = "🛏 \(room.price)원"
        Task {
            await self.updateStatusBadge(for: room, hostId: hostId)
        }
    }

    public func refreshStatus() {
        guard let room = currentRoom, let hostId = currentHostId else { return }
        Task {
            await self.updateStatusBadge(for: room, hostId: hostId)
        }
    }

    private var statusListener: ListenerRegistration?
    private func updateStatusBadge(for room: AccommodationRoom, hostId: String) async {
        // Remove previous listener if any
        statusListener?.remove()
        let db = Firestore.firestore()
        statusListener = db.collection("reserves")
            .whereField("hostId", isEqualTo: hostId)
            .whereField("roomId", isEqualTo: room.id)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                guard let documents = snapshot?.documents else { return }

                Task {
                    let today = Calendar.current.startOfDay(for: Date())
                    var found = false

                    for doc in documents {
                        let data = doc.data()
                        guard let checkInTimestamp = data["startDate"] as? Timestamp,
                              let checkOutTimestamp = data["endDate"] as? Timestamp,
                              let isCheckedIn = data["checkIn"] as? Bool,
                              let reservedRoomId = data["roomId"] as? String,
                              reservedRoomId == room.id else {
                            continue
                        }

                        let checkInDate = Calendar.current.startOfDay(for: checkInTimestamp.dateValue())
                        let checkOutDate = Calendar.current.startOfDay(for: checkOutTimestamp.dateValue())

                        if today >= checkInDate && today <= checkOutDate {
                            found = true
                            let status = isCheckedIn ? "투숙중" : "예약"
                            let badgeColor = isCheckedIn ? UIColor.systemRed : UIColor.systemBlue

                            let formatter = DateFormatter()
                            formatter.locale = Locale(identifier: "ko_KR")
                            formatter.dateFormat = "M월 d일"
                            let checkInDateString = formatter.string(from: checkInDate)
                            let checkOutDateString = formatter.string(from: checkOutDate)

                            if let userId = data["userId"] as? String {
                                let userRef = db.collection("users").document(userId)
                                Task {
                                    let userSnapshot = try? await userRef.getDocument()
                                    var guestName = "이름없음"
                                    if let userData = userSnapshot?.data(), let fetchedName = userData["name"] as? String {
                                        guestName = fetchedName
                                    }
                                    await MainActor.run {
                                        self.setBadge(text: status, color: badgeColor)
                                        self.reservationInfoLabel.isHidden = true
                                        self.nameLabel.text = "\(room.name) (\(guestName), \(checkInDateString) - \(checkOutDateString))"
                                    }
                                }
                            } else {
                                await MainActor.run {
                                    self.setBadge(text: status, color: badgeColor)
                                    self.reservationInfoLabel.isHidden = true
                                    self.nameLabel.text = "\(room.name) (이름없음, \(checkInDateString) - \(checkOutDateString))"
                                }
                            }
                            break
                        }
                    }

                    if !found {
                        await MainActor.run {
                            self.setBadge(text: "예약가능", color: .systemGreen)
                            self.reservationInfoLabel.isHidden = true
                        }
                    }
                }
            }
    }

    private func setBadge(text: String, color: UIColor) {
        DispatchQueue.main.async {
            self.statusBadge.text = text
            self.statusBadge.textColor = color

            switch text {
            case "예약가능":
                self.statusBadge.backgroundColor = UIColor(red: 0.9, green: 1.0, blue: 0.9, alpha: 1.0)
                self.statusBadge.textColor = UIColor(red: 47/255, green: 175/255, blue: 83/255, alpha: 1)
                self.containerView.backgroundColor = UIColor(red: 239/255, green: 249/255, blue: 243/255, alpha: 1)
            case "예약":
                self.statusBadge.backgroundColor = UIColor(red: 0.9, green: 0.95, blue: 1.0, alpha: 1.0)
                self.statusBadge.textColor = UIColor.systemBlue
                self.containerView.backgroundColor = UIColor(red: 239/255, green: 245/255, blue: 255/255, alpha: 1.0)
            case "투숙중":
                self.statusBadge.backgroundColor = UIColor(red: 1.0, green: 0.9, blue: 0.9, alpha: 1.0)
                self.statusBadge.textColor = UIColor.systemRed
                self.containerView.backgroundColor = UIColor(red: 255/255, green: 243/255, blue: 243/255, alpha: 1.0)
            default:
                self.statusBadge.backgroundColor = color.withAlphaComponent(0.1)
                self.containerView.backgroundColor = .white
            }
        }
    }

    private func setupUI() {
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.layer.cornerRadius = 12
        containerView.backgroundColor = UIColor(red: 239/255, green: 249/255, blue: 243/255, alpha: 1)
        containerView.layer.borderColor = UIColor.systemGray4.cgColor
        containerView.layer.borderWidth = 1
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOpacity = 0.05
        containerView.layer.shadowOffset = CGSize(width: 0, height: 2)
        containerView.layer.shadowRadius = 4
        contentView.addSubview(containerView)

        [nameLabel, occupancyLabel, priceLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        statusBadge.translatesAutoresizingMaskIntoConstraints = false
        editButton.translatesAutoresizingMaskIntoConstraints = false

        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        contentStackView.axis = .vertical
        contentStackView.spacing = 8
        contentStackView.alignment = .fill
        contentStackView.distribution = .fill

        occupancyPriceStackView.axis = .horizontal
        occupancyPriceStackView.spacing = 8
        occupancyPriceStackView.alignment = .fill
        occupancyPriceStackView.distribution = .fill
        occupancyPriceStackView.translatesAutoresizingMaskIntoConstraints = false

        occupancyPriceStackView.addArrangedSubview(occupancyLabel)
        occupancyPriceStackView.addArrangedSubview(priceLabel)

        contentStackView.addArrangedSubview(nameLabel)
        contentStackView.addArrangedSubview(occupancyPriceStackView)

        containerView.addSubview(contentStackView)
        containerView.addSubview(statusBadge)
        containerView.addSubview(editButton)

        reservationInfoLabel.translatesAutoresizingMaskIntoConstraints = false
        reservationInfoLabel.font = UIFont.systemFont(ofSize: 13)
        reservationInfoLabel.textColor = .darkGray
        reservationInfoLabel.textAlignment = .left
        reservationInfoLabel.numberOfLines = 0
        containerView.addSubview(reservationInfoLabel)
        reservationInfoLabel.isHidden = true

        editButton.setTitle("객실수정", for: .normal)
        editButton.setTitleColor(.white, for: .normal)
        editButton.backgroundColor = UIColor(red: 47/255, green: 175/255, blue: 83/255, alpha: 1)
        editButton.layer.cornerRadius = 8
        editButton.titleLabel?.font = UIFont.systemFont(ofSize: 14)

        nameLabel.font = UIFont.boldSystemFont(ofSize: 16)

        occupancyLabel.font = UIFont.systemFont(ofSize: 13)
        priceLabel.font = UIFont.systemFont(ofSize: 13)
        priceLabel.textAlignment = .right

        statusBadge.font = UIFont.systemFont(ofSize: 12)
        statusBadge.textColor = .systemGreen
        statusBadge.backgroundColor = UIColor(red: 0.9, green: 1.0, blue: 0.9, alpha: 1.0)
        statusBadge.layer.cornerRadius = 6
        statusBadge.clipsToBounds = true
        statusBadge.textAlignment = .center

        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),

            contentStackView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            contentStackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            contentStackView.trailingAnchor.constraint(equalTo: statusBadge.leadingAnchor, constant: -12),

            statusBadge.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            statusBadge.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            statusBadge.widthAnchor.constraint(equalToConstant: 60),
            statusBadge.heightAnchor.constraint(equalToConstant: 24),

            reservationInfoLabel.topAnchor.constraint(equalTo: contentStackView.bottomAnchor, constant: 12),
            reservationInfoLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),

            editButton.topAnchor.constraint(equalTo: reservationInfoLabel.bottomAnchor, constant: 20),
            editButton.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            editButton.widthAnchor.constraint(equalToConstant: 100),
            editButton.heightAnchor.constraint(equalToConstant: 36),
            editButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16)
        ])
    }
}
