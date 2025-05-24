//
//  FaceGuideOverlayView.swift
//  FaceInn
//
//  Created by CHOI on 5/24/25.
//

// 얼굴 촬영 가이드

import UIKit

final class FaceGuideOverlayView: UIView {

    // 현재 촬영할 얼굴 방향에 따라 안내 텍스트를 화면 상단에 표시하는 레이블
    private let guidanceLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    // 얼굴 인식 여부에 따라 가이드 프레임 색상을 변경 (녹색: 인식됨, 빨간색: 인식 안됨)
    var strokeColor: UIColor = .systemGreen {
        didSet {
            setNeedsDisplay()
        }
    }

    // 얼굴 방향을 나타내는 열거형 (정면, 좌측, 우측)
    enum FacePosition: String, CaseIterable {
        case front = "front"
        case left = "left"
        case right = "right"
    }

    // 현재 촬영 중인 얼굴 위치 (변경되면 프레임 및 텍스트 갱신)
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

    // 얼굴 가이드 이미지를 현재 위치에 따라 해당하는 이미지와 크기로 화면에 그림
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
    // 현재 얼굴 위치에 따라 상단에 표시되는 안내 문구를 업데이트
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
