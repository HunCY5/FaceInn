//
//  RecentRecognitionCell.swift
//  FaceInn
//
//  Created by CHOI on 6/2/25.
//

import UIKit

final class RecentRecognitionCell: UITableViewCell {
    static let identifier = "RecentRecognitionCell"

    private let statusDot = UIView()
    private let nameLabel = UILabel()
    private let roomLabel = UILabel()
    private let modeButton = UIButton(type: .system)
    private let timeLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        backgroundColor = .clear
        contentView.backgroundColor = .secondarySystemBackground
        contentView.layer.cornerRadius = 8

        statusDot.translatesAutoresizingMaskIntoConstraints = false
        statusDot.layer.cornerRadius = 6

        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)

        roomLabel.translatesAutoresizingMaskIntoConstraints = false
        roomLabel.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        roomLabel.textColor = .secondaryLabel

        modeButton.translatesAutoresizingMaskIntoConstraints = false
        modeButton.layer.cornerRadius = 12
        modeButton.titleLabel?.font = UIFont.systemFont(ofSize: 12, weight: .semibold)

        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        timeLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        timeLabel.textColor = .secondaryLabel

        contentView.addSubview(statusDot)
        contentView.addSubview(nameLabel)
        contentView.addSubview(roomLabel)
        contentView.addSubview(modeButton)
        contentView.addSubview(timeLabel)

        NSLayoutConstraint.activate([
            statusDot.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            statusDot.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            statusDot.widthAnchor.constraint(equalToConstant: 12),
            statusDot.heightAnchor.constraint(equalToConstant: 12),

            nameLabel.leadingAnchor.constraint(equalTo: statusDot.trailingAnchor, constant: 8),
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),

            roomLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            roomLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 2),

            modeButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            modeButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            modeButton.widthAnchor.constraint(equalToConstant: 60),
            modeButton.heightAnchor.constraint(equalToConstant: 24),

            timeLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            timeLabel.topAnchor.constraint(equalTo: modeButton.bottomAnchor, constant: 2)
        ])
    }

    func configure(with data: RecentRecognition) {
        nameLabel.text = data.guestName
        roomLabel.text = data.roomNumber
        timeLabel.text = data.time

        switch data.mode {
        case .checkin:
            statusDot.backgroundColor = .systemGreen
            modeButton.setTitle("체크인", for: .normal)
            modeButton.setTitleColor(.white, for: .normal)
            modeButton.backgroundColor = .systemGreen
        case .checkout:
            statusDot.backgroundColor = .systemRed
            modeButton.setTitle("체크아웃", for: .normal)
            modeButton.setTitleColor(.white, for: .normal)
            modeButton.backgroundColor = .systemBlue
        }
    }
}
