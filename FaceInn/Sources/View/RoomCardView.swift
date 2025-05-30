//
//  RoomCardView.swift
//  FaceInn
//
//  Created by 신찬솔 on 5/21/25.
//

import UIKit
import Kingfisher
import FirebaseAuth

final class RoomCardView: UIView {

    // Closure called when reserve button is tapped
    var onReserveButtonTapped: ((AccommodationRoom) -> Void)?

    private var numberOfNights: Int = 1

    private let scrollView = UIScrollView()
    private let imageStackView = UIStackView()
    private let nameLabel = UILabel()
    private let descriptionLabel = UILabel()
    private var occupancyLabel = UILabel()
    private var amenitiesLabel = UILabel()
    private let checkInOutLabel = UILabel()
    private let priceLabel = UILabel()
    private let reserveButton = UIButton(type: .system)
    private var currentRoom: AccommodationRoom?

    init(room: AccommodationRoom, numberOfNights: Int) {
        super.init(frame: .zero)
        setupView()
        configure(with: room, numberOfNights: numberOfNights)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        layer.cornerRadius = 12
        backgroundColor = .white
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.1
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowRadius = 4

        scrollView.isPagingEnabled = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        imageStackView.axis = .horizontal
        imageStackView.distribution = .fillEqually
        imageStackView.spacing = 0
        imageStackView.translatesAutoresizingMaskIntoConstraints = false

        scrollView.addSubview(imageStackView)
        addSubview(scrollView)

        nameLabel.font = .boldSystemFont(ofSize: 18)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false

        descriptionLabel.font = .systemFont(ofSize: 14)
        descriptionLabel.textColor = .darkGray
        descriptionLabel.numberOfLines = 0
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false

        let occupancyLabel = UILabel()
        occupancyLabel.font = .systemFont(ofSize: 14)
        occupancyLabel.textColor = .darkGray
        occupancyLabel.translatesAutoresizingMaskIntoConstraints = false
        self.occupancyLabel = occupancyLabel

        let amenitiesLabel = UILabel()
        amenitiesLabel.font = .systemFont(ofSize: 13)
        amenitiesLabel.textColor = .gray
        amenitiesLabel.numberOfLines = 1
        amenitiesLabel.translatesAutoresizingMaskIntoConstraints = false
        self.amenitiesLabel = amenitiesLabel

        checkInOutLabel.font = .systemFont(ofSize: 13)
        checkInOutLabel.textColor = .gray
        checkInOutLabel.translatesAutoresizingMaskIntoConstraints = false

        priceLabel.font = .boldSystemFont(ofSize: 16)
        priceLabel.textColor = .black
        priceLabel.translatesAutoresizingMaskIntoConstraints = false

        reserveButton.setTitle("숙박 예약", for: .normal)
        reserveButton.backgroundColor = UIColor(red: 47/255, green: 175/255, blue: 83/255, alpha: 1)
        reserveButton.tintColor = .white
        reserveButton.layer.cornerRadius = 6
        reserveButton.translatesAutoresizingMaskIntoConstraints = false
        reserveButton.addTarget(self, action: #selector(didTapReserveButton), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [nameLabel, descriptionLabel, occupancyLabel, amenitiesLabel, checkInOutLabel, priceLabel, reserveButton])
        stack.axis = .vertical
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false

        addSubview(stack)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.heightAnchor.constraint(equalToConstant: 200),

            imageStackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            imageStackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            imageStackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            imageStackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            imageStackView.heightAnchor.constraint(equalTo: scrollView.heightAnchor),

            stack.topAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: 12),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12)
        ])
    }

    func configure(with room: AccommodationRoom, numberOfNights: Int) {
        self.currentRoom = room
        self.numberOfNights = numberOfNights
        imageStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for urlString in room.imageURLs {
            let imageView = UIImageView()
            imageView.contentMode = .scaleAspectFit
            imageView.clipsToBounds = true
            imageView.kf.setImage(with: URL(string: urlString))
            imageStackView.addArrangedSubview(imageView)
            imageView.widthAnchor.constraint(equalTo: scrollView.widthAnchor).isActive = true
        }

        nameLabel.text = room.name
        descriptionLabel.text = room.description
        occupancyLabel.text = "최대 \(room.maxOccupancy)인"
        amenitiesLabel.text = room.amenities.prefix(3).joined(separator: ", ")
        checkInOutLabel.text = "입실 \(room.checkInTime) · 퇴실 \(room.checkOutTime)"
        let totalPrice = room.price * numberOfNights
        let priceText = NSMutableAttributedString(string: "\(totalPrice.formattedWithSeparator)원 /", attributes: [
            .foregroundColor: UIColor.black,
            .font: UIFont.boldSystemFont(ofSize: 16)
        ])
        priceText.append(NSAttributedString(string: " \(numberOfNights)박", attributes: [
            .foregroundColor: UIColor.darkGray,
            .font: UIFont.systemFont(ofSize: 13)
        ]))
        priceLabel.attributedText = priceText
        
        let selectedGuestCount = UserDefaults.standard.integer(forKey: "selectedGuestCount")
        if selectedGuestCount > room.maxOccupancy {
            reserveButton.setTitle("인원 초과", for: .normal)
            reserveButton.isEnabled = false
            reserveButton.backgroundColor = .lightGray
        } else {
            reserveButton.setTitle("숙박 예약", for: .normal)
            reserveButton.isEnabled = true
            reserveButton.backgroundColor = UIColor(red: 47/255, green: 175/255, blue: 83/255, alpha: 1)
        }
    }

    func updateGuestCount(_ newGuestCount: Int) {
        guard let room = currentRoom else { return }

        if newGuestCount > room.maxOccupancy {
            reserveButton.setTitle("인원 초과", for: .normal)
            reserveButton.isEnabled = false
            reserveButton.backgroundColor = .lightGray
        } else {
            reserveButton.setTitle("숙박 예약", for: .normal)
            reserveButton.isEnabled = true
            reserveButton.backgroundColor = UIColor(red: 47/255, green: 175/255, blue: 83/255, alpha: 1)
        }
    }

    func setReserveButtonEnabled(_ isEnabled: Bool) {
        reserveButton.isEnabled = isEnabled
        reserveButton.alpha = isEnabled ? 1.0 : 0.5
        reserveButton.backgroundColor = isEnabled ? UIColor(red: 47/255, green: 175/255, blue: 83/255, alpha: 1) : .lightGray
    }

    func setReserveButtonTitle(_ title: String) {
        reserveButton.setTitle(title, for: .normal)
    }
    @objc private func didTapReserveButton() {
        guard let room = currentRoom else { return }

        if Auth.auth().currentUser == nil || Auth.auth().currentUser?.isAnonymous == true {
            let alert = UIAlertController(title: "로그인이 필요합니다", message: "숙박 예약을 위해 로그인이 필요합니다.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "취소", style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(title: "로그인하기", style: .default, handler: { _ in
                // Assuming the current view is embedded in a view controller
                if let viewController = self.findViewController() {
                    let loginVC = LoginViewController()
                    loginVC.onLoginSuccess = {
                        // 로그인 후 돌아오기만 함
                    }
                    viewController.navigationController?.pushViewController(loginVC, animated: true)
                }
            }))
            if let viewController = self.findViewController() {
                viewController.present(alert, animated: true)
            }
            return
        }

        onReserveButtonTapped?(room)
    }

    private func findViewController() -> UIViewController? {
        var responder: UIResponder? = self
        while let r = responder {
            if let vc = r as? UIViewController {
                return vc
            }
            responder = r.next
        }
        return nil
    }
}

private extension Int {
    var formattedWithSeparator: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }
}
