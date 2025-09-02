//
//  GuestFaceRecognitionViewController.swift
//  FaceInn
//
//  Created by CHOI on 6/3/25.
//

import UIKit
import ARKit
import SceneKit
import Vision
import FirebaseAuth
import FirebaseFirestore

// 얼굴 인식 완료 시 알림을 전달하기 위한 델리게이트
protocol GuestFaceRecognitionDelegate: AnyObject {
    func guestFaceRecognitionDidComplete(reserveID: String, userID: String, userData: [String: Any], isCheckIn: Bool)
}

final class GuestFaceRecognitionViewController: UIViewController, ARSessionDelegate {
    weak var delegate: GuestFaceRecognitionDelegate?
    var recognitionType: RecognitionType = .checkIn // set before presenting
    
    // MARK: - UI 구성 요소
    private var cameraContainer: UIView!
    private var arView: ARSCNView!
    private let guideOverlayView = FaceGuideOverlayView()
    private var topLabel: UILabel!
    private var bottomLabel: UILabel!
    private var captureButton: UIButton!
    private var countdownLabel: UILabel?
    private var instructionLabel: UILabel?
    
    // 측면 안내 레이어 및 요(yaw) 목표값 (왼쪽/오른쪽 얼굴 위치)
    private var currentYawLayer: CAShapeLayer?
    private var targetYawLayer: CAShapeLayer?
    private let leftTargetYaw: Float = -30 * Float.pi / 180
    private let rightTargetYaw: Float = 30 * Float.pi / 180
    private var leftTargetX: CGFloat?
    private var rightTargetX: CGFloat?
    private var isFaceVisible = false
    
    // MARK: - 얼굴 촬영 상태
    private var currentFacePosition: FaceGuideOverlayView.FacePosition = .front
    private var faceImages: [FaceGuideOverlayView.FacePosition: UIImage] = [:]
    private var isFaceDetected = false
    private var isCountingDownActive = false
    private var countdownTimer: Timer?
    private var countdownCount = 3
    
    private let processor: FaceProcessor? = FaceProcessor()

    // MARK: - 기기별 레이아웃/임계치
    private struct LayoutProfile {
        // 원형 카메라 컨테이너 지름 비율
        let circleScale: CGFloat
        // 정면 가이드 프레임(사각형) 크기
        let guideSize: CGSize
        // 라벨/버튼 폰트 스케일
        let fontScale: CGFloat
        // 얼굴 박스 판정 임계치
        let minFaceSize: CGSize              // Vision faceRect 최소 크기
        let overlapRatioThreshold: CGFloat   // (교집합/face) 비율 임계치
        let heightRatioThreshold: CGFloat    // (교집합 높이/face 높이) 임계치
        // 오버레이 가이드 이미지 비율
        let guideWidthRatio: CGFloat
        let guideHeightRatio: CGFloat
        // 측면 점선
        let sideTargetBias: CGFloat
        // 좌/우 가이드 이미지 위치
        let sideImageLeftXRatio: CGFloat
        let sideImageRightXRatio: CGFloat

        func frontGuideRect(in bounds: CGRect) -> CGRect {
            let w = guideSize.width
            let h = guideSize.height
            return CGRect(x: bounds.midX - w/2, y: bounds.midY - h/2, width: w, height: h)
        }
    }

    // 현재 기기(iPhone/iPad)에 맞는 프로파일 반환
    private func currentLayoutProfile() -> LayoutProfile {
        if traitCollection.userInterfaceIdiom == .pad {
            // iPad
            return LayoutProfile(
                circleScale: 0.80,
                guideSize: CGSize(width: 300, height: 280),
                fontScale: 1.18,
                minFaceSize: CGSize(width: 120, height: 80),
                overlapRatioThreshold: 0.60,
                heightRatioThreshold: 0.60,
                guideWidthRatio: 0.30,
                guideHeightRatio: 0.45,
                sideTargetBias: 0.75,
                sideImageLeftXRatio: 0.28,         // 좌측 촬영 가이드 이미지 중앙으로
                sideImageRightXRatio: 0.72         // 우측 촬영 가이드 이미지 중앙으로
            )
        } else {
            // iPhone
            return LayoutProfile(
                circleScale: 0.90,
                guideSize: CGSize(width: 300, height: 280),
                fontScale: 1.0,
                minFaceSize: CGSize(width: 140, height: 90),
                overlapRatioThreshold: 0.65,
                heightRatioThreshold: 0.65,
                guideWidthRatio: 0.50,
                guideHeightRatio: 0.75,
                sideTargetBias: 1.0,               // iPhone: 기존 위치 유지
                sideImageLeftXRatio: 0.20,         // iPhone: 현행 유지
                sideImageRightXRatio: 0.80
            )
        }
    }

    // 정면 가이드 프레임 계산 (기기별 프로파일 적용)
    private var frontGuideRect: CGRect {
        return currentLayoutProfile().frontGuideRect(in: view.bounds)
    }

    // MARK: - 디버그용 정면 인식 박스 레이어
    private var debugFrontBoxLayer: CAShapeLayer?

    private func showDebugFrontGuideBox() {
        debugFrontBoxLayer?.removeFromSuperlayer()
        let layer = CAShapeLayer()
        layer.frame = view.bounds
        let path = UIBezierPath(rect: frontGuideRect)
        layer.path = path.cgPath
        layer.strokeColor = UIColor.yellow.withAlphaComponent(0.8).cgColor
        layer.lineWidth = 2
        layer.fillColor = UIColor.clear.cgColor
        view.layer.addSublayer(layer)
        debugFrontBoxLayer = layer
    }
    
    // MARK: - 생명 주기 메서드
    enum RecognitionType {
        case checkIn, checkOut
    }
    
    
    // 뷰 로드 후 초기 설정
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupCameraContainer()
        setupARSession()
        setupGuideOverlay()
        setupLabelsAndButton()
    }

    // 화면이 나타날 때 탭바 숨기기
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.tabBar.isHidden = true
        // AR 세션 재시작
        if let config = arView.session.configuration {
            arView.session.run(config, options: [.resetTracking, .removeExistingAnchors])
        }
    }

    // 화면이 사라질 때 탭바 보이기
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        tabBarController?.tabBar.isHidden = false
    }

    // MARK: - UI 설정
    // 카메라 컨테이너 뷰 설정
    private func setupCameraContainer() {
        cameraContainer = UIView(frame: .zero)
        cameraContainer.layer.cornerRadius = 0 // viewDidLayoutSubviews에서 원형 반영
        cameraContainer.layer.masksToBounds = true
        cameraContainer.backgroundColor = .clear
        cameraContainer.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(cameraContainer)
    }
    
    // 가이드 오버레이 뷰 설정
    private func setupGuideOverlay() {
        guideOverlayView.frame = cameraContainer.bounds
        guideOverlayView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        guideOverlayView.currentPosition = .front
        cameraContainer.addSubview(guideOverlayView)
    }
    
    // 상단/하단 라벨 및 버튼 설정
    private func setupLabelsAndButton() {
        topLabel = UILabel()
        topLabel.text = "얼굴 정면을 가이드 프레임 안에 맞춰주세요"
        topLabel.textColor = .white
        topLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        topLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(topLabel)
        NSLayoutConstraint.activate([
            topLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            topLabel.bottomAnchor.constraint(equalTo: cameraContainer.topAnchor, constant: -16)
        ])
        
        bottomLabel = UILabel()
        bottomLabel.text = "준비가 되면 아래 버튼을 눌러 얼굴 인식을 시작하세요"
        bottomLabel.textColor = .white
        bottomLabel.font = UIFont.systemFont(ofSize: 15)
        bottomLabel.textAlignment = .center
        bottomLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bottomLabel)
        NSLayoutConstraint.activate([
            bottomLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            bottomLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -110)
        ])
        
        captureButton = UIButton(type: .system)
        captureButton.setTitle("인식시작", for: .normal)
        captureButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        captureButton.setTitleColor(.white, for: .normal)
        captureButton.backgroundColor = UIColor.systemGreen
        captureButton.layer.cornerRadius = 10
        captureButton.clipsToBounds = true
        captureButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(captureButton)
        NSLayoutConstraint.activate([
            captureButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            captureButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -40),
            captureButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
            captureButton.heightAnchor.constraint(equalToConstant: 50)
        ])
        captureButton.addTarget(self, action: #selector(handleManualCapture), for: .touchUpInside)
    }

    // MARK: - 레이아웃 갱신 (아이폰/아이패드 분리 적용)
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let profile = currentLayoutProfile()

        // 1) 원형 카메라 컨테이너 크기/위치 계산
        let shortSide = min(view.bounds.width, view.bounds.height)
        let diameter = shortSide * profile.circleScale
        let frame = CGRect(
            x: (view.bounds.width - diameter) / 2,
            y: (view.bounds.height - diameter) / 2,
            width: diameter,
            height: diameter
        )
        cameraContainer.frame = frame
        cameraContainer.layer.cornerRadius = diameter / 2

        // 2) AR 뷰 & 오버레이 동기화
        arView?.frame = cameraContainer.bounds
        guideOverlayView.frame = cameraContainer.bounds
        // 가이드 이미지 비율(기기별) 전달
        guideOverlayView.guideWidthRatio = profile.guideWidthRatio
        guideOverlayView.guideHeightRatio = profile.guideHeightRatio
        guideOverlayView.sideImageLeftXRatio = profile.sideImageLeftXRatio
        guideOverlayView.sideImageRightXRatio = profile.sideImageRightXRatio
        guideOverlayView.setNeedsDisplay()

        // 3) 라벨/버튼 폰트 스케일
        topLabel?.font = UIFont.systemFont(ofSize: 18 * profile.fontScale, weight: .semibold)
        bottomLabel?.font = UIFont.systemFont(ofSize: 15 * profile.fontScale)
        captureButton?.titleLabel?.font = UIFont.systemFont(ofSize: 18 * profile.fontScale, weight: .semibold)
        if let heightConstraint = (captureButton?.constraints.first { $0.firstAttribute == .height }) {
            heightConstraint.constant = 50 * profile.fontScale
        }

        // 디버그 박스 표시
        showDebugFrontGuideBox()
    }
    
    // AR 세션 설정
    private func setupARSession() {
        arView = ARSCNView(frame: cameraContainer.bounds)
        arView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        arView.session.delegate = self
        cameraContainer.addSubview(arView)
        let config = ARFaceTrackingConfiguration()
        config.isLightEstimationEnabled = true
        arView.session.run(config, options: [.resetTracking, .removeExistingAnchors])
        cameraContainer.bringSubviewToFront(guideOverlayView)
    }
    
    // MARK: - 버튼 액션
    // 수동 촬영 버튼 눌렀을 때 처리
    @objc private func handleManualCapture() {
        guard isFaceDetected else {
            showAlert(title: "얼굴 인식 필요", message: "프레임에 얼굴을 맞춰주세요")
            return
        }
        
        // 이전 인식 세션에서 남은 얼굴 이미지 캐시 제거 (상태는 유지)
        faceImages.removeAll()
        currentFacePosition = .front
        guideOverlayView.currentPosition = .front
        isCountingDownActive = true
        topLabel.removeFromSuperview()
        captureButton.isHidden = true
        bottomLabel.isHidden = true
        
        countdownLabel = UILabel()
        countdownLabel?.textColor = .white
        countdownLabel?.font = UIFont.systemFont(ofSize: 60, weight: .bold)
        countdownLabel?.textAlignment = .center
        countdownLabel?.translatesAutoresizingMaskIntoConstraints = false
        if let cd = countdownLabel {
            view.addSubview(cd)
            NSLayoutConstraint.activate([
                cd.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                cd.bottomAnchor.constraint(equalTo: cameraContainer.topAnchor, constant: -16)
            ])
        }
        
        instructionLabel = UILabel()
        instructionLabel?.text = "3초 후 자동으로 촬영됩니다"
        instructionLabel?.textColor = .white
        instructionLabel?.font = UIFont.systemFont(ofSize: 15)
        instructionLabel?.textAlignment = .center
        instructionLabel?.translatesAutoresizingMaskIntoConstraints = false
        if let il = instructionLabel {
            view.addSubview(il)
            NSLayoutConstraint.activate([
                il.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                il.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -110)
            ])
        }
        startCountdown()
    }
    
    // MARK: - 카운트다운
    // 카운트다운 시작
    private func startCountdown() {
        // 기존 안내문구 항상 제거
        instructionLabel?.removeFromSuperview()
        instructionLabel = nil

        countdownCount = 3
        countdownLabel?.text = "\(countdownCount)"
        let newInstr = UILabel()
        newInstr.text = "3초 후 자동으로 촬영됩니다"
        newInstr.textColor = .white
        newInstr.font = UIFont.systemFont(ofSize: 15)
        newInstr.textAlignment = .center
        newInstr.translatesAutoresizingMaskIntoConstraints = false
        instructionLabel = newInstr
        view.addSubview(newInstr)
        NSLayoutConstraint.activate([
            newInstr.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            newInstr.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -110)
        ])
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self = self else { return }
            self.countdownCount -= 1
            if self.countdownCount > 0 {
                self.countdownLabel?.text = "\(self.countdownCount)"
            } else {
                timer.invalidate()
                self.countdownTimer = nil
                self.countdownLabel?.removeFromSuperview()
                self.instructionLabel?.removeFromSuperview()
                self.countdownLabel = nil
                self.instructionLabel = nil
                self.isCountingDownActive = false
                self.capturePhoto()
            }
        }
    }
    
    // 카운트다운 리셋 및 안내문구 복원
    private func resetCountdown() {
        // 타이머 중단
        countdownTimer?.invalidate()
        countdownTimer = nil
        // 카운트다운 숫자를 "3"으로 고정
        countdownCount = 3
        countdownLabel?.text = "\(countdownCount)"
        // 기존 안내 라벨 제거
        instructionLabel?.removeFromSuperview()
        instructionLabel = nil
        if let caution = view.viewWithTag(9001) {
            caution.removeFromSuperview()
        }
        // 카운트다운 모드는 비활성화 (단, front 모드에서는 true 유지)
        if currentFacePosition != .front {
            isCountingDownActive = false
        }
        // 왼쪽/오른쪽 측면 모드일 때: 안내+주의 라벨 모두 하단에 재배치
        if currentFacePosition == .left || currentFacePosition == .right {
            let isLeft = currentFacePosition == .left
            // 안내 라벨
            let newInstructionLabel = UILabel()
            newInstructionLabel.text = isLeft ? "얼굴을 왼쪽으로 살짝 돌려주세요" : "얼굴을 오른쪽으로 살짝 돌려주세요"
            newInstructionLabel.textColor = .white
            newInstructionLabel.font = UIFont.systemFont(ofSize: 15)
            newInstructionLabel.textAlignment = .center
            newInstructionLabel.translatesAutoresizingMaskIntoConstraints = false
            instructionLabel = newInstructionLabel
            view.addSubview(newInstructionLabel)
            NSLayoutConstraint.activate([
                newInstructionLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                newInstructionLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -110)
            ])
            // 주의 라벨
            let cautionLabel = UILabel()
            cautionLabel.text = "얼굴이 화면 밖으로 나가면 안됩니다"
            cautionLabel.textColor = .systemYellow
            cautionLabel.font = UIFont.systemFont(ofSize: 14)
            cautionLabel.textAlignment = .center
            cautionLabel.translatesAutoresizingMaskIntoConstraints = false
            cautionLabel.tag = 9001
            view.addSubview(cautionLabel)
            NSLayoutConstraint.activate([
                cautionLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                cautionLabel.topAnchor.constraint(equalTo: newInstructionLabel.bottomAnchor, constant: 10)
            ])
        } else {
            // 정면 등 다른 모드: 기존대로
            let newInstructionLabel = UILabel()
            newInstructionLabel.text = "얼굴 정면을 가이드 프레임 안에 맞춰주세요"
            newInstructionLabel.textColor = .white
            newInstructionLabel.font = UIFont.systemFont(ofSize: 15)
            newInstructionLabel.textAlignment = .center
            newInstructionLabel.translatesAutoresizingMaskIntoConstraints = false
            instructionLabel = newInstructionLabel
            view.addSubview(newInstructionLabel)
            NSLayoutConstraint.activate([
                newInstructionLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                newInstructionLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -110)
            ])
        }
        guideOverlayView.strokeColor = .red
    }
    
    // MARK: - ARSessionDelegate (AR 세션 델리게이트)
    // AR 세션이 업데이트될 때 호출됨
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        // 좌측/우측 모드인 경우 ARFaceAnchor를 사용하여 실시간 위치 계산
        if currentFacePosition == .left || currentFacePosition == .right {
            let faceAnchor = frame.anchors.compactMap { $0 as? ARFaceAnchor }.first
            if let faceAnchor = faceAnchor {
                DispatchQueue.main.async {
                    let node = SCNNode()
                    node.simdTransform = faceAnchor.transform
                    let projectedPoint = self.arView.projectPoint(node.position)
                    let projectedCGPoint = CGPoint(x: CGFloat(projectedPoint.x), y: CGFloat(projectedPoint.y))
                    let center = CGPoint(x: self.cameraContainer.bounds.midX, y: self.cameraContainer.bounds.midY)
                    let radius = min(self.cameraContainer.bounds.width, self.cameraContainer.bounds.height) / 2
                    let dx = projectedCGPoint.x - center.x
                    let dy = projectedCGPoint.y - center.y
                    let distance = sqrt(dx*dx + dy*dy)
                    let isInsideCircle = distance < radius * 0.9
                    // --- Inserted logic per instructions ---
                    if isInsideCircle {
                        if (!self.isFaceVisible || (self.countdownTimer == nil && self.isCountingDownActive)) {
                            self.isFaceVisible = true
                            self.startCountdown()
                            // 안내/주의 텍스트도 startCountdown, resetCountdown에서 책임지므로 중복 생성 X
                        }
                    } else {
                        if self.isFaceVisible {
                            self.isFaceVisible = false
                            self.resetCountdown()
                        }
                    }
                    // (The rest: updateCurrentYawVisualization if insideCircle)
                    if isInsideCircle {
                        if self.currentFacePosition == .left {
                            self.updateCurrentYawVisualization(faceAnchor: faceAnchor)
                        } else {
                            self.updateCurrentYawVisualizationRight(faceAnchor: faceAnchor)
                        }
                    }
                }
            } else {
                DispatchQueue.main.async {
                    if self.isFaceVisible {
                        self.isFaceVisible = false
                    }
                    self.currentYawLayer?.isHidden = true
                    self.targetYawLayer?.strokeColor = UIColor.red.cgColor
                }
            }
            return
        }
        // Otherwise, for front:
        let pixelBuffer = frame.capturedImage
        validateFrontFace(on: pixelBuffer)
    }
    
    // 정면 얼굴 유효성 검사(Vision 사용)
    private func validateFrontFace(on pixelBuffer: CVPixelBuffer) {
        // 사각형 기반 얼굴 검출로 대체 (Guest)
        performRectangleRequest(on: pixelBuffer)
        return
    }
    
    // MARK: - 촬영 및 진행
    // 사진 촬영 및 이미지 변환
    private func capturePhoto() {
        guard let currentFrame = arView.session.currentFrame else { return }
        let pixelBuffer = currentFrame.capturedImage
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext()
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return }
        let image = UIImage(cgImage: cgImage)
        saveFaceImage(image)
    }
    
    // 촬영된 얼굴 이미지 저장
    private func saveFaceImage(_ image: UIImage) {
        faceImages[currentFacePosition] = image
        DispatchQueue.main.async {
            self.advanceToNextFacePosition()
        }
    }
    
    // 다음 얼굴 위치로 전환 또는 임베딩 추출 진행
    private func advanceToNextFacePosition() {
        if let next = FaceGuideOverlayView.FacePosition.allCases.first(where: { !faceImages.keys.contains($0) }) {
            currentFacePosition = next
            guideOverlayView.currentPosition = currentFacePosition
            guideOverlayView.strokeColor = .red
            instructionLabel?.removeFromSuperview()
            instructionLabel = nil
            switch next {
            case .front:
                topLabel.text = "얼굴 정면을 가이드 프레임 안에 맞춰주세요"
                captureButton.isHidden = false
                bottomLabel.isHidden = false
            case .left:
                setupLeftMode()
            case .right:
                setupRightMode()
            }
        } else {
            // all three positions captured → extract embeddings
            extractAllEmbeddings()
        }
    }

    // MARK: - 측면 모드 설정 및 시각화 (FaceCaptureViewController에서 복사)
    // 왼쪽 측면 모드 설정
    private func setupLeftMode() {
        guideOverlayView.strokeColor = .red
        captureButton.isHidden = true
        bottomLabel.isHidden = true
        instructionLabel?.removeFromSuperview()
        instructionLabel = nil
        if let caution = view.viewWithTag(9001) {
            caution.removeFromSuperview()
        }
        let newInstructionLabel = UILabel()
        newInstructionLabel.text = "얼굴을 왼쪽으로 살짝 돌려주세요"
        newInstructionLabel.textColor = .white
        newInstructionLabel.font = UIFont.systemFont(ofSize: 15)
        newInstructionLabel.textAlignment = .center
        newInstructionLabel.translatesAutoresizingMaskIntoConstraints = false
        instructionLabel = newInstructionLabel
        view.addSubview(newInstructionLabel)
        NSLayoutConstraint.activate([
            newInstructionLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            newInstructionLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -110)
        ])
        let cautionLabel = UILabel()
        cautionLabel.text = "얼굴이 화면 밖으로 나가면 안됩니다"
        cautionLabel.textColor = .systemYellow
        cautionLabel.font = UIFont.systemFont(ofSize: 14)
        cautionLabel.textAlignment = .center
        cautionLabel.translatesAutoresizingMaskIntoConstraints = false
        cautionLabel.tag = 9001
        view.addSubview(cautionLabel)
        NSLayoutConstraint.activate([
            cautionLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            cautionLabel.topAnchor.constraint(equalTo: newInstructionLabel.bottomAnchor, constant: 10)
        ])
        configureLeftGuidanceLayers()
    }

    // 오른쪽 측면 모드 설정
    private func setupRightMode() {
        guideOverlayView.strokeColor = .red
        captureButton.isHidden = true
        bottomLabel.isHidden = true
        instructionLabel?.removeFromSuperview()
        instructionLabel = nil
        if let caution = view.viewWithTag(9001) {
            caution.removeFromSuperview()
        }
        let newInstructionLabel = UILabel()
        newInstructionLabel.text = "얼굴을 오른쪽으로 살짝 돌려주세요"
        newInstructionLabel.textColor = .white
        newInstructionLabel.font = UIFont.systemFont(ofSize: 15)
        newInstructionLabel.textAlignment = .center
        newInstructionLabel.translatesAutoresizingMaskIntoConstraints = false
        instructionLabel = newInstructionLabel
        view.addSubview(newInstructionLabel)
        NSLayoutConstraint.activate([
            newInstructionLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            newInstructionLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -110)
        ])
        let cautionLabel = UILabel()
        cautionLabel.text = "얼굴이 화면 밖으로 나가면 안됩니다"
        cautionLabel.textColor = .systemYellow
        cautionLabel.font = UIFont.systemFont(ofSize: 14)
        cautionLabel.textAlignment = .center
        cautionLabel.translatesAutoresizingMaskIntoConstraints = false
        cautionLabel.tag = 9001
        view.addSubview(cautionLabel)
        NSLayoutConstraint.activate([
            cautionLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            cautionLabel.topAnchor.constraint(equalTo: newInstructionLabel.bottomAnchor, constant: 10)
        ])
        configureRightGuidanceLayers()
    }

    // 왼쪽 측면 요 시각화 레이어 구성
    private func configureLeftGuidanceLayers() {
        cameraContainer.layoutIfNeeded()
        targetYawLayer?.removeFromSuperlayer()
        currentYawLayer?.removeFromSuperlayer()

        let containerBounds = cameraContainer.bounds
        let fullLeftYaw: Float = -Float.pi / 2
        let normalizedTarget = leftTargetYaw / fullLeftYaw
        let targetX = containerBounds.midX - (containerBounds.width / 2) * CGFloat(normalizedTarget) * currentLayoutProfile().sideTargetBias

        let targetPath = UIBezierPath()
        targetPath.move(to: CGPoint(x: targetX, y: 0))
        targetPath.addLine(to: CGPoint(x: targetX, y: containerBounds.height))

        let dashedLayer = CAShapeLayer()
        dashedLayer.frame = containerBounds
        dashedLayer.path = targetPath.cgPath
        dashedLayer.strokeColor = UIColor.white.withAlphaComponent(0.7).cgColor
        dashedLayer.lineWidth = 4
        dashedLayer.lineDashPattern = [4, 6]
        dashedLayer.fillColor = UIColor.clear.cgColor
        cameraContainer.layer.addSublayer(dashedLayer)
        targetYawLayer = dashedLayer
        leftTargetX = targetX

        let currentLayer = CAShapeLayer()
        currentLayer.frame = containerBounds
        currentLayer.strokeColor = UIColor.white.cgColor
        currentLayer.lineWidth = 6
        currentLayer.fillColor = UIColor.clear.cgColor
        cameraContainer.layer.addSublayer(currentLayer)
        currentYawLayer = currentLayer
    }

    // 오른쪽 측면 요 시각화 레이어 구성
    private func configureRightGuidanceLayers() {
        cameraContainer.layoutIfNeeded()
        targetYawLayer?.removeFromSuperlayer()
        currentYawLayer?.removeFromSuperlayer()

        let containerBounds = cameraContainer.bounds
        let fullRightYaw: Float = Float.pi / 2
        let normalizedTarget = rightTargetYaw / fullRightYaw
        let targetX = containerBounds.midX + (containerBounds.width / 2) * CGFloat(normalizedTarget) * currentLayoutProfile().sideTargetBias

        let targetPath = UIBezierPath()
        targetPath.move(to: CGPoint(x: targetX, y: 0))
        targetPath.addLine(to: CGPoint(x: targetX, y: containerBounds.height))

        let dashedLayer = CAShapeLayer()
        dashedLayer.frame = containerBounds
        dashedLayer.path = targetPath.cgPath
        dashedLayer.strokeColor = UIColor.white.withAlphaComponent(0.7).cgColor
        dashedLayer.lineWidth = 4
        dashedLayer.lineDashPattern = [4, 6]
        dashedLayer.fillColor = UIColor.clear.cgColor
        cameraContainer.layer.addSublayer(dashedLayer)
        targetYawLayer = dashedLayer
        rightTargetX = targetX

        let currentLayer = CAShapeLayer()
        currentLayer.frame = containerBounds
        currentLayer.strokeColor = UIColor.white.cgColor
        currentLayer.lineWidth = 6
        currentLayer.fillColor = UIColor.clear.cgColor
        cameraContainer.layer.addSublayer(currentLayer)
        currentYawLayer = currentLayer
    }

    // 현재 얼굴 요 좌표 시각화 (왼쪽)
    private func updateCurrentYawVisualization(faceAnchor: ARFaceAnchor) {
        cameraContainer.layoutIfNeeded()
        guard let currentLayer = currentYawLayer, let targetX = leftTargetX else { return }
        let containerBounds = cameraContainer.bounds
        let noseIndex = 9
        guard faceAnchor.geometry.vertices.count > noseIndex else { return }
        let noseVertex = faceAnchor.geometry.vertices[noseIndex]
        let noseWorldPosition = faceAnchor.transform * simd_float4(noseVertex.x, noseVertex.y, noseVertex.z, 1.0)
        let nosePosition3D = SCNVector3(noseWorldPosition.x, noseWorldPosition.y, noseWorldPosition.z)
        let projectedNose = arView.projectPoint(nosePosition3D)
        let currentX = CGFloat(projectedNose.x)
        let linePath = UIBezierPath()
        linePath.move(to: CGPoint(x: currentX - containerBounds.minX, y: 0))
        linePath.addLine(to: CGPoint(x: currentX - containerBounds.minX, y: containerBounds.height))
        currentLayer.path = linePath.cgPath
        let diffX = abs(currentX - targetX)
        let containerDiameter = min(self.cameraContainer.bounds.width, self.cameraContainer.bounds.height)
        let pixelThreshold: CGFloat = containerDiameter * 0.012 // 직경의 1.2%
        if isCountingDownActive {
            guideOverlayView.strokeColor = .green
        } else {
            guideOverlayView.strokeColor = .red
        }
        if diffX < pixelThreshold && countdownTimer == nil {
            instructionLabel?.removeFromSuperview()
            instructionLabel = nil
            if let caution = view.viewWithTag(9001) {
                caution.removeFromSuperview()
            }
            let newInstructionLabel = UILabel()
            newInstructionLabel.text = "3초 후 자동으로 촬영됩니다"
            newInstructionLabel.textColor = .white
            newInstructionLabel.font = UIFont.systemFont(ofSize: 15)
            newInstructionLabel.textAlignment = .center
            newInstructionLabel.translatesAutoresizingMaskIntoConstraints = false
            instructionLabel = newInstructionLabel
            view.addSubview(newInstructionLabel)
            NSLayoutConstraint.activate([
                newInstructionLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                newInstructionLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -110)
            ])
            isCountingDownActive = true
            if countdownLabel == nil {
                let newCountdownLabel = UILabel()
                newCountdownLabel.textColor = .white
                newCountdownLabel.font = UIFont.systemFont(ofSize: 60, weight: .bold)
                newCountdownLabel.textAlignment = .center
                newCountdownLabel.translatesAutoresizingMaskIntoConstraints = false
                countdownLabel = newCountdownLabel
                view.addSubview(newCountdownLabel)
                NSLayoutConstraint.activate([
                    newCountdownLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                    newCountdownLabel.bottomAnchor.constraint(equalTo: cameraContainer.topAnchor, constant: -16)
                ])
            }
            countdownLabel?.text = "\(countdownCount)"
            startCountdown()
        } else if diffX >= pixelThreshold && countdownTimer != nil {
            resetCountdown()
        }
    }

    // 현재 얼굴 요 좌표 시각화 (오른쪽)
    private func updateCurrentYawVisualizationRight(faceAnchor: ARFaceAnchor) {
        cameraContainer.layoutIfNeeded()
        guard let currentLayer = currentYawLayer, let targetX = rightTargetX else { return }
        let containerBounds = cameraContainer.bounds
        let noseIndex = 9
        guard faceAnchor.geometry.vertices.count > noseIndex else { return }
        let noseVertex = faceAnchor.geometry.vertices[noseIndex]
        let noseWorldPosition = faceAnchor.transform * simd_float4(noseVertex.x, noseVertex.y, noseVertex.z, 1.0)
        let nosePosition3D = SCNVector3(noseWorldPosition.x, noseWorldPosition.y, noseWorldPosition.z)
        let projectedNose = arView.projectPoint(nosePosition3D)
        let currentX = CGFloat(projectedNose.x)
        let linePath = UIBezierPath()
        linePath.move(to: CGPoint(x: currentX - containerBounds.minX, y: 0))
        linePath.addLine(to: CGPoint(x: currentX - containerBounds.minX, y: containerBounds.height))
        currentLayer.path = linePath.cgPath
        let diffX = abs(currentX - targetX)
        let containerDiameter = min(self.cameraContainer.bounds.width, self.cameraContainer.bounds.height)
        let pixelThreshold: CGFloat = containerDiameter * 0.012 // 직경의 1.2%
        if isCountingDownActive {
            guideOverlayView.strokeColor = .green
        } else {
            guideOverlayView.strokeColor = .red
        }
        if diffX < pixelThreshold && countdownTimer == nil {
            instructionLabel?.removeFromSuperview()
            instructionLabel = nil
            if let caution = view.viewWithTag(9001) {
                caution.removeFromSuperview()
            }
            let newInstructionLabel = UILabel()
            newInstructionLabel.text = "3초 후 자동으로 촬영됩니다"
            newInstructionLabel.textColor = .white
            newInstructionLabel.font = UIFont.systemFont(ofSize: 15)
            newInstructionLabel.textAlignment = .center
            newInstructionLabel.translatesAutoresizingMaskIntoConstraints = false
            instructionLabel = newInstructionLabel
            view.addSubview(newInstructionLabel)
            NSLayoutConstraint.activate([
                newInstructionLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                newInstructionLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -110)
            ])
            isCountingDownActive = true
            if countdownLabel == nil {
                let newCountdownLabel = UILabel()
                newCountdownLabel.textColor = .white
                newCountdownLabel.font = UIFont.systemFont(ofSize: 60, weight: .bold)
                newCountdownLabel.textAlignment = .center
                newCountdownLabel.translatesAutoresizingMaskIntoConstraints = false
                countdownLabel = newCountdownLabel
                view.addSubview(newCountdownLabel)
                NSLayoutConstraint.activate([
                    newCountdownLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                    newCountdownLabel.bottomAnchor.constraint(equalTo: cameraContainer.topAnchor, constant: -16)
                ])
            }
            countdownLabel?.text = "\(countdownCount)"
            startCountdown()
        } else if diffX >= pixelThreshold && countdownTimer != nil {
            resetCountdown()
        }
    }
    
    // 모든 얼굴 이미지 임베딩 추출
    private func extractAllEmbeddings() {
        var vectors: [FaceGuideOverlayView.FacePosition: [Float]] = [:]
        let dispatchGroup = DispatchGroup()
        
        for (position, image) in faceImages {
            // 1) UIImage를 orientation 반영한 CGImage로 변환
            let srcSize = image.size
            let orientedImage = UIGraphicsImageRenderer(size: srcSize).image { _ in
                image.draw(in: CGRect(origin: .zero, size: srcSize))
            }
            guard let cg = orientedImage.cgImage else { continue }

            // 2) Vision으로 얼굴 박스 검출 (정면/측면 공통, 실패 시 전체 프레임 fallback)
            var faceRectPix = CGRect(x: 0, y: 0, width: cg.width, height: cg.height)
            let handler = VNImageRequestHandler(cgImage: cg, options: [:])
            let req = VNDetectFaceRectanglesRequest()
            do {
                try handler.perform([req])
                if let bbox = (req.results as? [VNFaceObservation])?.first?.boundingBox, bbox != .zero {
                    faceRectPix = VNImageRectForNormalizedRect(bbox, cg.width, cg.height)
                }
            } catch {
                print("Vision face detect failed: \(error.localizedDescription). Using full frame.")
            }

            // 3) 얼굴 박스 기준으로 112x112 BGRA/sRGB 픽셀버퍼 생성 (Aspect-Fill)
            if let buffer = orientedImage.pixelBuffer(cropRect: faceRectPix, width: 112, height: 112, aspectFill: true), let proc = processor {
                dispatchGroup.enter()
                proc.extractFaceEmbedding(from: buffer) { vector in
                    if let v = vector {
                        vectors[position] = v
                    }
                    dispatchGroup.leave()
                }
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            self.performComparison(with: vectors)
        }
    }
    
    // MARK: - 유틸: Firestore 벡터 안전 변환
    // Firestore에 [NSNumber]/[Double]/[Float] 등 다양한 형태로 저장될 수 있으므로 안전하게 [Float]로 변환
    private func toFloatArray(_ any: Any?) -> [Float]? {
        // nil 방어
        guard let any = any else { return nil }
        // 이미 [Float]
        if let v = any as? [Float] { return v }
        // [Double] → [Float]
        if let v = any as? [Double] { return v.map { Float($0) } }
        // [NSNumber] → [Float]
        if let v = any as? [NSNumber] { return v.map { $0.floatValue } }
        // [[NSNumber]] (잘못 저장된 케이스) → 1차원 플랫
        if let vv = any as? [[NSNumber]] { return vv.flatMap { $0.map { $0.floatValue } } }
        // Data로 직렬화된 경우 (옵션)
        if let data = any as? Data {
            // 128차원 가정: 길이가 맞지 않으면 실패 처리
            let count = 128
            if data.count == count * MemoryLayout<Float>.size {
                var arr = [Float](repeating: 0, count: count)
                _ = arr.withUnsafeMutableBytes { data.copyBytes(to: $0)}
                return arr
            }
        }
        // 예상 외 타입 (예: Date/Timestamp 등) → nil
        return nil
    }

    // MARK: - Firestore 비교 로직
    // 게스트 벡터와 저장된 벡터 비교
    private func performComparison(with guestVectors: [FaceGuideOverlayView.FacePosition: [Float]]) {
        guard let hostID = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        let now = Date()
        let calendar = Calendar.current
        
        let startOfToday = calendar.startOfDay(for: now)
        let startOfTomorrow = calendar.date(byAdding: .day, value: 1, to: startOfToday)!
        

        
        var query: Query = db.collection("reserves")
            .whereField("hostId", isEqualTo: hostID)
            .whereField("useFaceId", isEqualTo: true)
        
        switch recognitionType {
        case .checkIn:
            query = query
                .whereField("startDate", isGreaterThanOrEqualTo: Timestamp(date: startOfToday))
                .whereField("startDate", isLessThan: Timestamp(date: startOfTomorrow))
        case .checkOut:
            query = query
                .whereField("endDate", isGreaterThanOrEqualTo: Timestamp(date: startOfToday))
                .whereField("endDate", isLessThan: Timestamp(date: startOfTomorrow))
        }
        
        query.getDocuments { snapshot, error in
            if let error = error {
                print("Firestore error: \(error.localizedDescription)")
                self.showAlert(title: "에러", message: "예약 정보를 불러올 수 없습니다.\n\(error.localizedDescription)")
                return
            }
            guard let docs = snapshot?.documents, !docs.isEmpty else {
                // 예약 정보 없음 시 알림 및 이전 화면으로 자동 복귀
                DispatchQueue.main.async {
                    // 카메라 및 AR 세션 정리
                    self.countdownTimer?.invalidate()
                    self.countdownTimer = nil
                    self.countdownLabel?.removeFromSuperview()
                    self.instructionLabel?.removeFromSuperview()
                    self.arView.session.pause()
                    self.arView.removeFromSuperview()

                    // 알림 표시
                    let alert = UIAlertController(title: "예약 정보 없음", message: "일치하는 예약 정보가 없습니다.", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "확인", style: .default))
                    self.present(alert, animated: true)

                    // 10초 후 자동 복귀
                    DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                        if self.presentedViewController === alert {
                            alert.dismiss(animated: true) {
                                _ = self.navigationController?.popViewController(animated: true)
                            }
                        }
                    }
                }
                return
            }

            print("Firestore query returned \(docs.count) documents")
            let reserveIDs = docs.map { $0.documentID }
            print("  ▶️ Retrieved reserveIDs:", reserveIDs)

            // For each reserve, fetch user vectors and compare
            for doc in docs {
                let data = doc.data()
                let reserveID = doc.documentID
                print("Processing reserveID: \(reserveID)")

                guard let userID = data["userId"] as? String else {
                    print("  → reserveID \(reserveID) has no userID field")
                    continue
                }
                print("  → Found userID: \(userID)")

                db.collection("users").document(userID).getDocument { userSnap, err in
                    if let err = err {
                        print("  → 유저 데이터 불러오기 실패 for userID \(userID): \(err.localizedDescription)")
                        return
                    }
                    guard let userData = userSnap?.data() else {
                        print("  → userID \(userID) has no data")
                        return
                    }
                    // 다양한 저장 형태([NSNumber]/[Double]/[Float]/Data 등)를 안전하게 [Float]로 변환
                    guard let frontVec = self.toFloatArray(userData["front_vector"]),
                          let leftVec  = self.toFloatArray(userData["left_vector"]),
                          let rightVec = self.toFloatArray(userData["right_vector"]) else {
                        print("  → userID \(userID) vector type mismatch (expected array-like)")
                        return
                    }

                    guard let gvFront = guestVectors[.front],
                          let gvLeft = guestVectors[.left],
                          let gvRight = guestVectors[.right] else {
                        print("  → guestVectors missing one of front/left/right")
                        return
                    }

                    // 디버그: 차원 로그
                    print("Dims guest/front/left/right → \(gvFront.count)/\(frontVec.count)/\(gvLeft.count)/\(leftVec.count)/\(gvRight.count)/\(rightVec.count)")

                    // -- 코사인 유사도 --
                    func cosine(_ a: [Float], _ b: [Float]) -> Float {
                        // 길이 체크
                        guard a.count == b.count, a.count > 0 else { return -1 }
                        // 내적/노름 계산
                        var dot: Float = 0
                        var aa: Float = 0
                        var bb: Float = 0
                        for i in 0..<a.count {
                            let x = a[i]
                            let y = b[i]
                            dot += x * y
                            aa += x * x
                            bb += y * y
                        }
                        let denom = sqrt(aa) * sqrt(bb)
                        if denom == 0 || !denom.isFinite { return -1 }
                        let v = dot / denom
                        return v.isFinite ? v : -1
                    }

                    let cosFront = cosine(gvFront, frontVec)
                    let cosLeft  = cosine(gvLeft,  leftVec)
                    let cosRight = cosine(gvRight, rightVec)
                    print("Cosine similarities → front: \(cosFront), left: \(cosLeft), right: \(cosRight)")

                    let thresholdCos: Float = 0.7 // 기준 값
                    if cosFront > thresholdCos && cosLeft > thresholdCos && cosRight > thresholdCos {
                        print("✅ Cosine match success for userID \(userID), reserveID \(reserveID)")
                        DispatchQueue.main.async {
                            let reserveInfoVC = ReserveInfoViewController()
                            reserveInfoVC.reserveID = reserveID
                            reserveInfoVC.userID = userID
                            reserveInfoVC.userData = userData
                            reserveInfoVC.isCheckIn = (self.recognitionType == .checkIn)
                            reserveInfoVC.reserveData = data
                            self.resetRecognitionSession()
                            if let nav = self.navigationController {
                                nav.pushViewController(reserveInfoVC, animated: true)
                            } else {
                                self.present(reserveInfoVC, animated: true)
                            }
                        }
                    } else {
                        print("❌ Cosine match failure for userID \(userID), reserveID \(reserveID)")
                    }
                }
            }
        }
    }

    // MARK: - 세션/캐시 초기화 유틸
    private func resetRecognitionSession() {
        // 얼굴 이미지/벡터 캐시 제거
        faceImages.removeAll()
        // 카운트다운/라벨/가이드 상태 정리
        countdownTimer?.invalidate()
        countdownTimer = nil
        countdownLabel?.removeFromSuperview()
        instructionLabel?.removeFromSuperview()
        countdownLabel = nil
        instructionLabel = nil
        // 위치/표시 상태 리셋
        currentFacePosition = .front
        guideOverlayView.currentPosition = .front
        guideOverlayView.strokeColor = .red
        isFaceDetected = false
        isCountingDownActive = false
        // AR 세션 일시 중지(중복 네비/중복 캡처 방지)
        arView?.session.pause()
    }
    
    // MARK: - showAlert
    private func showAlert(title: String, message: String) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "확인", style: .default))
            self.present(alert, animated: true)
        }
    }
    // Fallback: Vision 직사각형 검출 요청 공통 처리 (Guest 모드)
    private func performRectangleRequest(on pixelBuffer: CVPixelBuffer) {
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .leftMirrored, options: [:])
        let rectRequest = VNDetectFaceRectanglesRequest { [weak self] request, error in
            guard let self = self else { return }
            let faceRect = VNImageRectForNormalizedRect(
                (request.results as? [VNFaceObservation])?.first?.boundingBox ?? .zero,
                Int(self.view.bounds.width),
                Int(self.view.bounds.height)
            )
            let guideRect = self.frontGuideRect
            let intersection = guideRect.intersection(faceRect)
            let intersectionArea = intersection.width * intersection.height
            let faceArea = faceRect.width * faceRect.height
            let heightRatio = intersection.height / faceRect.height
            let profile = self.currentLayoutProfile()
            let isValid = faceArea > 0 &&
                          (intersectionArea / faceArea > profile.overlapRatioThreshold) &&
                          (heightRatio > profile.heightRatioThreshold) &&
                          faceRect.width  >= profile.minFaceSize.width &&
                          faceRect.height >= profile.minFaceSize.height
            DispatchQueue.main.async {
                self.guideOverlayView.strokeColor = isValid ? .green : .red
                self.isFaceDetected = isValid
                if self.isCountingDownActive {
                    if isValid && self.countdownTimer == nil {
                        self.startCountdown()
                    } else if !isValid && self.countdownTimer != nil {
                        self.resetCountdown()
                    }
                }
            }
        }
        try? handler.perform([rectRequest])
    }
}
