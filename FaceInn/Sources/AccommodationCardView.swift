//
//  AccommodationCardView.swift
//  FaceInn
//
//  Created by 신찬솔 on 5/18/25.
//

import UIKit
import FirebaseStorage

final class AccommodationCardView: UIView {

    let imageView = UIImageView()
    let nameLabel = UILabel()
    let locationLabel = UILabel()
    let priceLabel = UILabel()
    let ratingLabel = UILabel()
    let viewDetailButton = UIButton()
    let heartButton = UIButton()

    private var isLiked = false
    
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

        viewDetailButton.setTitle("View Details", for: .normal)
        viewDetailButton.setTitleColor(.white, for: .normal)
        viewDetailButton.backgroundColor = UIColor(red: 47/255, green: 175/255, blue: 83/255, alpha: 1)
        viewDetailButton.titleLabel?.font = .systemFont(ofSize: 13)
        viewDetailButton.layer.cornerRadius = 6
        addSubview(viewDetailButton)

        heartButton.setImage(UIImage(systemName: "heart"), for: .normal)
        heartButton.tintColor = .gray
        addSubview(heartButton)
        
        heartButton.addTarget(self, action: #selector(heartButtonTapped), for: .touchUpInside)
    }
    @objc private func heartButtonTapped() {
           isLiked.toggle()
           let heartImageName = isLiked ? "heart.fill" : "heart"
           heartButton.setImage(UIImage(systemName: heartImageName), for: .normal)
           heartButton.tintColor = isLiked ? .systemRed : .gray
       }

    private func setupLayout() {
        [imageView, nameLabel, locationLabel, priceLabel, ratingLabel, viewDetailButton, heartButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            imageView.heightAnchor.constraint(equalToConstant: 200),

            heartButton.topAnchor.constraint(equalTo: imageView.topAnchor, constant: 8),
            heartButton.trailingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: -8),

            nameLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 8),
            nameLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),

            locationLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            locationLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),

            priceLabel.topAnchor.constraint(equalTo: locationLabel.bottomAnchor, constant: 8),
            priceLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),

            ratingLabel.centerYAnchor.constraint(equalTo: priceLabel.centerYAnchor),
            ratingLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),

            viewDetailButton.topAnchor.constraint(equalTo: priceLabel.bottomAnchor, constant: 10),
            viewDetailButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            viewDetailButton.widthAnchor.constraint(equalToConstant: 100),
            viewDetailButton.heightAnchor.constraint(equalToConstant: 30),

            viewDetailButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10)
        ])
    }

    func configure(with model: Accommodation) {
        nameLabel.text = model.name
        locationLabel.text = model.location
        priceLabel.text = "₩\(model.price) / night"
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
            URLSession.shared.dataTask(with: url) { data, _, error in
                if let error = error {
                    print("❌ 이미지 다운로드 실패: \(error.localizedDescription)")
                    return
                }
                guard let data = data else {
                    print("❗️ 이미지 데이터가 없음")
                    return
                }
                DispatchQueue.main.async {
                    self.imageView.image = UIImage(data: data)
                    print("✅ 이미지 적용 완료")
                }
            }.resume()
        } else {
            print("⚠️ imageURLs가 비었거나 잘못됨: \(model.imageURLs ?? [])")
        }
    }
}
