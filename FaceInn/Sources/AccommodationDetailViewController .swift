//
//  AccommodationDetailViewController .swift
//  FaceInn
//
//  Created by 신찬솔 on 5/20/25.
//

import UIKit
import Kingfisher

final class AccommodationDetailViewController: UIViewController, UICollectionViewDataSource {

    var accommodation: Accommodation?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        self.hidesBottomBarWhenPushed = true
        self.title = accommodation?.name

        // Top image gallery
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
        view.addSubview(imageGallery)

        // Title Label
        let titleLabel = UILabel()
        titleLabel.text = accommodation?.name ?? "숙소 이름"
        titleLabel.font = UIFont.boldSystemFont(ofSize: 22)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)

        // Address Label
        let addressLabel = UILabel()
        addressLabel.text = accommodation?.location ?? "주소 정보 없음"
        addressLabel.font = UIFont.systemFont(ofSize: 16)
        addressLabel.textColor = .darkGray
        addressLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(addressLabel)

        // Rating Label
        let ratingLabel = UILabel()
        if let rating = accommodation?.rating, let reviewCount = accommodation?.reviewCount {
            ratingLabel.text = "⭐️ \(rating) (\(reviewCount)개 평가)"
        } else {
            ratingLabel.text = "⭐️ 평가 정보 없음"
        }
        ratingLabel.font = UIFont.systemFont(ofSize: 15)
        ratingLabel.textColor = .darkGray
        ratingLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(ratingLabel)

        // Layout constraints
        NSLayoutConstraint.activate([
            imageGallery.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            imageGallery.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            imageGallery.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            imageGallery.heightAnchor.constraint(equalToConstant: 250),

            titleLabel.topAnchor.constraint(equalTo: imageGallery.bottomAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            addressLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            addressLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            addressLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),

            ratingLabel.topAnchor.constraint(equalTo: addressLabel.bottomAnchor, constant: 8),
            ratingLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            ratingLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
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
