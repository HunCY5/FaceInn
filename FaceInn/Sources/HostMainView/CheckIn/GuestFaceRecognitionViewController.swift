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
    }

    // 화면이 사라질 때 탭바 보이기
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        tabBarController?.tabBar.isHidden = false
    }

    // MARK: - UI 설정
    // 카메라 컨테이너 뷰 설정
    private func setupCameraContainer() {
        let size: CGFloat = min(view.bounds.width, view.bounds.height) * 0.9
        cameraContainer = UIView(frame: CGRect(
            x: (view.bounds.width - size) / 2,
            y: (view.bounds.height - size) / 2,
            width: size,
            height: size
        ))
        cameraContainer.layer.cornerRadius = size / 2
        cameraContainer.layer.masksToBounds = true
        cameraContainer.backgroundColor = .clear
        cameraContainer.autoresizingMask = [.flexibleLeftMargin, .flexibleRightMargin,
                                            .flexibleTopMargin, .flexibleBottomMargin]
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
        let orientation: CGImagePropertyOrientation = .leftMirrored
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: orientation, options: [:])
        let request = VNDetectFaceLandmarksRequest { [weak self] req, error in
            guard let self = self else { return }
            guard let observations = req.results as? [VNFaceObservation], let obs = observations.first else {
                DispatchQueue.main.async {
                    self.guideOverlayView.strokeColor = .red
                    self.isFaceDetected = false
                    if self.isCountingDownActive, self.countdownTimer != nil {
                        self.resetCountdown()
                    }
                }
                return
            }
            let faceBox = VNImageRectForNormalizedRect(
                obs.boundingBox,
                Int(self.view.bounds.width),
                Int(self.view.bounds.height)
            )
            // UIKit의 guideRect를 Vision의 정규화된 regionOfInterest 좌표로 변환
            let guideRect = CGRect(x: self.view.bounds.midX - 150, y: self.view.bounds.midY - 140, width: 300, height: 280)
            let intersection = guideRect.intersection(faceBox)
            let intersectionArea = intersection.width * intersection.height
            let faceArea = faceBox.width * faceBox.height
            let heightRatio = intersection.height / faceBox.height
            let areaThreshold: CGFloat = 0.65
            let heightThreshold: CGFloat = 0.65
            let isWithinGuide = faceArea > 0 && (intersectionArea / faceArea > areaThreshold)
            let isWithinHeight = heightRatio > heightThreshold
            let minWidth: CGFloat = 140
            let minHeight: CGFloat = 90
            let isLargeEnough = faceBox.width >= minWidth && faceBox.height >= minHeight
            let isValid = isWithinGuide && isWithinHeight && isLargeEnough

            DispatchQueue.main.async {
                self.guideOverlayView.strokeColor = isValid ? .green : .red
                let prev = self.isFaceDetected
                self.isFaceDetected = isValid

                if self.isCountingDownActive {
                    if self.isFaceDetected {
                        if self.countdownTimer == nil {
                            self.startCountdown()
                        }
                    } else {
                        if self.countdownTimer != nil {
                            self.resetCountdown()
                        }
                    }
                }
            }
        }
        try? handler.perform([request])
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
        let targetX = containerBounds.midX - (containerBounds.width / 2) * CGFloat(normalizedTarget)

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
        let targetX = containerBounds.midX + (containerBounds.width / 2) * CGFloat(normalizedTarget)

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
        let pixelThreshold: CGFloat = 10
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
        let pixelThreshold: CGFloat = 10
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
            if let buffer = image.pixelBuffer(width: 112, height: 112), let proc = processor {
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
                print("No matching reserve documents found.")
                self.showAlert(title: "예약 정보 없음", message: "일치하는 예약 정보가 없습니다.")
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
                    guard let userData = userSnap?.data(),
                          let frontVec = userData["front_vector"] as? [Float],
                          let leftVec = userData["left_vector"] as? [Float],
                          let rightVec = userData["right_vector"] as? [Float] else {
                        print("  → userID \(userID) missing vector fields")
                        
                        return
                    }
                    
                    
                    
                    print("Comparing vectors for userID: \(userID), reserveID: \(reserveID)")
                    // Compare each vector distance
                    let threshold: Float = 0.6 // adjust as needed
                    func l2(_ a: [Float], _ b: [Float]) -> Float {
                        zip(a, b).map { ($0 - $1) * ($0 - $1) }.reduce(0, +)
                    }
                    guard let gvFront = guestVectors[.front],
                          let gvLeft = guestVectors[.left],
                          let gvRight = guestVectors[.right] else {
                        print("  → guestVectors missing one of front/left/right")
                        return
                    }
                    
                    let distFront = l2(gvFront, frontVec)
                    let distLeft  = l2(gvLeft,  leftVec)
                    let distRight = l2(gvRight, rightVec)
                    print("  → Distances - front: \(distFront), left: \(distLeft), right: \(distRight), threshold: \(threshold)")
                    
                    // If all distances below threshold
                    if distFront < threshold && distLeft < threshold && distRight < threshold {
                        print("  → Vectors matched for userID \(userID), reserveID \(reserveID)")
                        DispatchQueue.main.async {
                            // ReserveInfoViewController로 직접 push 및 데이터 전달
                            let reserveInfoVC = ReserveInfoViewController()
                            reserveInfoVC.reserveID = reserveID
                            reserveInfoVC.userID = userID
                            reserveInfoVC.userData = userData
                            reserveInfoVC.isCheckIn = (self.recognitionType == .checkIn)
                            reserveInfoVC.reserveData = data
                            if let nav = self.navigationController {
                                nav.pushViewController(reserveInfoVC, animated: true)
                            } else {
                                self.present(reserveInfoVC, animated: true)
                            }
                            // self.dismiss(animated: true) // push 방식에서는 필요 없음
                        }
                    } else {
                        print("  → Vectors did NOT match for userID \(userID)")
                    }
                }
            }
        }
    }
    
    // MARK: - 도우미 메서드
    // 알림 표시
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default) { _ in
            self.dismiss(animated: true)
        })
        present(alert, animated: true)
    }
}
