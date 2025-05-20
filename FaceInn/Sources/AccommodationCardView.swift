//
//  AccommodationCardView.swift
//  FaceInn
//
//  Created by 신찬솔 on 5/18/25.
//

import UIKit
import FirebaseStorage
import FirebaseAuth
import FirebaseFirestore

final class AccommodationCardView: UIView {

    let imageView = UIImageView()
    let nameLabel = UILabel()
    let locationLabel = UILabel()
    let priceLabel = UILabel()
    let ratingLabel = UILabel()
    let heartButton = UIButton()
    
    var isLiked = false
    private var accommodationId: String?
    
    var onCardTapped: (() -> Void)?
    var onLikeRequested: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupLayout()
        backgroundColor = .white
        layer.cornerRadius = 12
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.1
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowRadius = 4
        clipsToBounds = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 10
        addSubview(imageView)

        nameLabel.font = .boldSystemFont(ofSize: 16)
        addSubview(nameLabel)

        locationLabel.font = .systemFont(ofSize: 14)
        locationLabel.textColor = .gray
        addSubview(locationLabel)

        priceLabel.font = .boldSystemFont(ofSize: 15)
        addSubview(priceLabel)

        ratingLabel.font = .systemFont(ofSize: 13)
        ratingLabel.textColor = .systemOrange
        addSubview(ratingLabel)

        heartButton.setImage(UIImage(systemName: "heart"), for: .normal)
        heartButton.tintColor = .gray
        heartButton.backgroundColor = UIColor.white.withAlphaComponent(0.8)
        heartButton.layer.cornerRadius = 18
        heartButton.clipsToBounds = true
        addSubview(heartButton)
        
        heartButton.addTarget(self, action: #selector(heartButtonTapped), for: .touchUpInside)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(cardTapped))
        self.addGestureRecognizer(tapGesture)
        self.isUserInteractionEnabled = true
    }
    @objc private func heartButtonTapped() {
        guard let user = Auth.auth().currentUser, !user.isAnonymous else {
            onLikeRequested?()
            return
        }
        
        guard let accommodationId = accommodationId else { return }
        
        isLiked.toggle()
        let heartImageName = isLiked ? "heart.fill" : "heart"
        heartButton.setImage(UIImage(systemName: heartImageName), for: .normal)
        heartButton.tintColor = isLiked ? .systemRed : .gray
        
        let userRef = Firestore.firestore().collection("users").document(user.uid)
        if isLiked {
            userRef.updateData([
                "wishList": FieldValue.arrayUnion([accommodationId])
            ])
        } else {
            userRef.updateData([
                "wishList": FieldValue.arrayRemove([accommodationId])
            ])
        }
    }

    // Public method to allow external triggering of like toggling
    func toggleLike() {
        guard let user = Auth.auth().currentUser, !user.isAnonymous else {
            onLikeRequested?()
            return
        }
        
        guard let accommodationId = accommodationId else { return }
        
        isLiked.toggle()
        let heartImageName = isLiked ? "heart.fill" : "heart"
        heartButton.setImage(UIImage(systemName: heartImageName), for: .normal)
        heartButton.tintColor = isLiked ? .systemRed : .gray
        
        let userRef = Firestore.firestore().collection("users").document(user.uid)
        if isLiked {
            userRef.updateData([
                "wishList": FieldValue.arrayUnion([accommodationId])
            ])
        } else {
            userRef.updateData([
                "wishList": FieldValue.arrayRemove([accommodationId])
            ])
        }
    }
    
    @objc private func cardTapped() {
        onCardTapped?()
    }

    private func setupLayout() {
        [imageView, nameLabel, locationLabel, priceLabel, ratingLabel, heartButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            imageView.heightAnchor.constraint(equalToConstant: 200),

            heartButton.topAnchor.constraint(equalTo: imageView.topAnchor, constant: 12),
            heartButton.trailingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: -12),
            heartButton.widthAnchor.constraint(equalToConstant: 36),
            heartButton.heightAnchor.constraint(equalToConstant: 36),

            nameLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 8),
            nameLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),

            locationLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            locationLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),

            priceLabel.topAnchor.constraint(equalTo: locationLabel.bottomAnchor, constant: 8),
            priceLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),

            ratingLabel.centerYAnchor.constraint(equalTo: priceLabel.centerYAnchor),
            ratingLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),

            priceLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10)
        ])
    }

    func configure(with model: Accommodation) {
        self.accommodationId = model.id
        nameLabel.text = model.name
        locationLabel.text = model.location

        let guestCount = UserDefaults.standard.integer(forKey: "selectedGuestCount")

        let startDate = UserDefaults.standard.object(forKey: "selectedStartDate") as? Date
        let endDate = UserDefaults.standard.object(forKey: "selectedEndDate") as? Date

        var numberOfNights = 1
        if let start = startDate, let end = endDate {
            let nights = Calendar.current.dateComponents([.day], from: start, to: end).day ?? 0
            numberOfNights = max(1, nights)
        }

        if let rooms = model.rooms {
            // 인원 조건에 맞는 룸 가격들 필터링
            let validPrices = rooms.compactMap { roomDict -> Int? in
                guard
                    let occupancy = roomDict["maxOccupancy"] as? Int,
                    let price = roomDict["price"] as? Int
                else { return nil }

                return occupancy >= guestCount ? price : nil
            }

            if let lowestPrice = validPrices.min() {
                let formatter = NumberFormatter()
                formatter.numberStyle = .decimal
                let formattedPrice = formatter.string(from: NSNumber(value: lowestPrice)) ?? "\(lowestPrice)"
                let totalPrice = lowestPrice * numberOfNights
                let totalFormatted = formatter.string(from: NSNumber(value: totalPrice)) ?? "\(totalPrice)"
                // Use attributed string for price label
                let priceText = NSMutableAttributedString(string: "₩\(totalFormatted) / ", attributes: [
                    .foregroundColor: UIColor.black
                ])
                priceText.append(NSAttributedString(string: "\(numberOfNights)박", attributes: [
                    .foregroundColor: UIColor.darkGray,
                    .font: UIFont.systemFont(ofSize: 13)
                ]))
                priceLabel.attributedText = priceText
            } else {
                // Use attributed string for unavailable price
                let priceUnavailableText = NSMutableAttributedString(string: "₩- / ", attributes: [
                    .foregroundColor: UIColor.black
                ])
                priceUnavailableText.append(NSAttributedString(string: "\(numberOfNights)박", attributes: [
                    .foregroundColor: UIColor.darkGray,
                    .font: UIFont.systemFont(ofSize: 13)
                ]))
                priceLabel.attributedText = priceUnavailableText // 조건에 맞는 방 없음
            }
        } else {
            priceLabel.text = "₩- / 박" // rooms 정보 없음
        }
        let star = "⭐️ "
        let ratingString = String(format: "%.1f", model.rating)
        let reviewString = " (\(model.reviewCount))"

        // NSMutableAttributedString 생성
        let fullText = NSMutableAttributedString(string: star, attributes: [
            .foregroundColor: UIColor.systemOrange
        ])
        fullText.append(NSAttributedString(string: ratingString, attributes: [
            .foregroundColor: UIColor.black
        ]))
        fullText.append(NSAttributedString(string: reviewString, attributes: [
            .foregroundColor: UIColor.gray
        ]))

        ratingLabel.attributedText = fullText

        if let urlString = model.imageURLs?.first, let url = URL(string: urlString) {
            print("📸 이미지 URL 시도: \(urlString)")
            // Remove existing activity indicators
            imageView.subviews.forEach { if $0 is UIActivityIndicatorView { $0.removeFromSuperview() } }

            // Set loading animation before starting image load
            imageView.image = nil
            let activity = UIActivityIndicatorView(style: .medium)
            activity.color = .darkGray
            activity.translatesAutoresizingMaskIntoConstraints = false
            imageView.addSubview(activity)
            NSLayoutConstraint.activate([
                activity.centerXAnchor.constraint(equalTo: imageView.centerXAnchor),
                activity.centerYAnchor.constraint(equalTo: imageView.centerYAnchor)
            ])
            activity.startAnimating()

            URLSession.shared.dataTask(with: url) { data, _, error in
                if let error = error {
                    print("❌ 이미지 다운로드 실패: \(error.localizedDescription)")
                    DispatchQueue.main.async {
                        activity.stopAnimating()
                        activity.removeFromSuperview()
                    }
                    return
                }
                guard let data = data else {
                    print("❗️ 이미지 데이터가 없음")
                    DispatchQueue.main.async {
                        activity.stopAnimating()
                        activity.removeFromSuperview()
                    }
                    return
                }
                DispatchQueue.main.async {
                    self.imageView.image = UIImage(data: data)
                    activity.stopAnimating()
                    activity.removeFromSuperview()
                    print("✅ 이미지 적용 완료")
                }
            }.resume()
        } else {
            print("⚠️ imageURLs가 비었거나 잘못됨: \(model.imageURLs ?? [])")
        }
        updateHeartState()
    }
    
    private func updateHeartState() {
        guard let accommodationId = self.accommodationId else {
            self.setHeartState(isLiked: false)
            return
        }

        guard let user = Auth.auth().currentUser, !user.isAnonymous else {
            self.setHeartState(isLiked: false)
            return
        }

        let userRef = Firestore.firestore().collection("users").document(user.uid)
        userRef.getDocument { snapshot, error in
            var isLiked = false
            if let data = snapshot?.data(),
               let wishList = data["wishList"] as? [String] {
                isLiked = wishList.contains(accommodationId)
            }

            DispatchQueue.main.async {
                self.setHeartState(isLiked: isLiked)
            }
        }
    }
    
    private func setHeartState(isLiked: Bool) {
        self.isLiked = isLiked
        let heartImageName = isLiked ? "heart.fill" : "heart"
        heartButton.setImage(UIImage(systemName: heartImageName), for: .normal)
        heartButton.tintColor = isLiked ? .systemRed : .gray
    }
    
}
