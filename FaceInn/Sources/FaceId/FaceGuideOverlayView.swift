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
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        // Remove guidanceLabel from overlay
        isUserInteractionEnabled = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // 얼굴 가이드 이미지를 현재 위치에 따라 해당하는 이미지와 크기로 화면에 그림
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        context.clear(rect)

        // 반투명 검정 배경
        context.setFillColor(UIColor.black.withAlphaComponent(0.5).cgColor)
        context.fill(rect)

        // 중앙 원형 투명 구멍
        let radius = min(rect.width, rect.height) / 2
        let circlePath = UIBezierPath(
            ovalIn: CGRect(
                x: rect.midX - radius,
                y: rect.midY - radius,
                width: radius * 2,
                height: radius * 2
            )
        )
        context.addPath(circlePath.cgPath)
        context.setBlendMode(.clear)
        context.fillPath()
        context.setBlendMode(.normal)

        // 가이드 이미지 크기: 컨테이너 크기에 대한 비율
        let guideWidth = rect.width * 0.5
        let guideHeight = rect.height * 0.75
        let imageSize = CGSize(width: guideWidth, height: guideHeight)

        // 이미지 이름 선택
        let imageName: String
        let isDetected = strokeColor == .green
        switch currentPosition {
        case .front:
            imageName = isDetected ? "guide_front_green" : "guide_front_red"
        case .left:
            imageName = isDetected ? "guide_right_green" : "guide_right_red"
        case .right:
            imageName = isDetected ? "guide_left_green" : "guide_left_red"
        }

        guard let image = UIImage(named: imageName) else { return }

        // 이미지 위치 계산
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
                x: rect.width * 0.2,
                y: (rect.height - imageSize.height) / 2,
                width: imageSize.width,
                height: imageSize.height
            )
        case .right:
            imageRect = CGRect(
                x: rect.width * 0.8 - imageSize.width,
                y: (rect.height - imageSize.height) / 2,
                width: imageSize.width,
                height: imageSize.height
            )
        }

        // 가이드 이미지 렌더링
        image.draw(in: imageRect)

        // 외곽 원형 테두리
        context.setStrokeColor(strokeColor.cgColor)
        context.setLineWidth(4)
        context.addEllipse(in: CGRect(
            x: rect.midX - radius,
            y: rect.midY - radius,
            width: radius * 2,
            height: radius * 2
        ))
        context.strokePath()
    }
    // 안내 문구 레이블 제거됨 (FaceCaptureViewController에서 라벨 직접 추가)
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

