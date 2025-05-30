//
//  AccommodationCell.swift
//  FaceInn
//
//  Created by 신찬솔 on 5/18/25.
//

import UIKit

final class AccommodationCell: UICollectionViewCell {
    static let identifier = "AccommodationCell"

    private let cardView = AccommodationCardView()

    var onCardTapped: (() -> Void)? {
        didSet {
            cardView.onCardTapped = onCardTapped
        }
    }

    var onLikeRequested: (() -> Void)? {
        didSet {
            cardView.onLikeRequested = onLikeRequested
        }
    }

    var onLikeChanged: (() -> Void)? {
        didSet {
            cardView.onLikeChanged = onLikeChanged
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(cardView)
        cardView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with model: Accommodation) {
        cardView.configure(with: model)
    }

    func toggleLike() {
        cardView.toggleLike()
    }

    var isLiked: Bool {
        return cardView.isLiked
    }
}
