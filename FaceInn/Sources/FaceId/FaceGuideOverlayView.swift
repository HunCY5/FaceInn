//
//  FaceGuideOverlayView.swift
//  FaceInn
//
//  Created by CHOI on 5/24/25.
//

// 얼굴 촬영 가이드

import UIKit

final class FaceGuideOverlayView: UIView {

    private let guidanceLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    var strokeColor: UIColor = .systemGreen {
        didSet {
            setNeedsDisplay()
        }
    }

    enum FacePosition: String, CaseIterable {
        case front = "front"
        case left = "left"
        case right = "right"
    }

    var currentPosition: FacePosition = .front {
        didSet {
            setNeedsDisplay()
            updateGuidanceText()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        addSubview(guidanceLabel)
        NSLayoutConstraint.activate([
            guidanceLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            guidanceLabel.topAnchor.constraint(equalTo: topAnchor, constant: 80)
        ])
        updateGuidanceText()
        isUserInteractionEnabled = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }

        context.clear(rect)

        let imageName: String
        let imageSize: CGSize

        let isDetected = strokeColor == .green

        switch currentPosition {
        case .front:
            imageName = isDetected ? "guide_front_green" : "guide_front_red"
            imageSize = CGSize(width: 300, height: 360)
        case .left:
            imageName = isDetected ? "guide_right_green" : "guide_right_red"
            imageSize = CGSize(width: 260, height: 312)
        case .right:
            imageName = isDetected ? "guide_left_green" : "guide_left_red"
            imageSize = CGSize(width: 260, height: 312)
        }

        guard let image = UIImage(named: imageName) else { return }

        let imageRect: CGRect
        switch currentPosition {
        case .front:
            imageRect = CGRect(
                x: (rect.width - imageSize.width) / 2,
                y: (rect.height - imageSize.height) / 2,
                width: imageSize.width,
                height: imageSize.height
            )
        case .left:
            imageRect = CGRect(
                x: rect.width * 0.15,
                y: (rect.height - imageSize.height) / 2,
                width: imageSize.width,
                height: imageSize.height
            )
        case .right:
            imageRect = CGRect(
                x: rect.width * 0.85 - imageSize.width,
                y: (rect.height - imageSize.height) / 2,
                width: imageSize.width,
                height: imageSize.height
            )
        }

        image.draw(in: imageRect, blendMode: .normal, alpha: 1.0)
    }
    private func updateGuidanceText() {
        switch currentPosition {
        case .front:
            guidanceLabel.text = "얼굴 정면을 보여주세요"
        case .left:
            guidanceLabel.text = "얼굴 우측을 보여주세요"
        case .right:
            guidanceLabel.text = "얼굴 좌측을 보여주세요"
        }
    }
}

extension FaceGuideOverlayView.FacePosition: CustomStringConvertible {
    var description: String {
        switch self {
        case .left: return "우측 얼굴"
        case .front: return "정면 얼굴"
        case .right: return "좌측 얼굴"
        }
    }
}
