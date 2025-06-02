//
//  FaceCaptureViewController.swift
//  FaceInn
//
//  Created by CHOI on 5/23/25.
//

// 카메라 세션 초기화
// 사용 기술: AVFoundation

import UIKit
import ARKit
import SceneKit
import Vision
import FirebaseFirestore
import FirebaseAuth


final class FaceCaptureViewController: UIViewController, ARSessionDelegate {
    weak var delegate: FaceCaptureDelegate?
    var shouldDismissToRoot: Bool = false
    var documentId: String?
    // 카메라 원형 컨테이너 뷰 참조용 프로퍼티
    private var cameraContainer: UIView!
    // ARKit 얼굴 트래킹 뷰
    private var arView: ARSCNView!
    private var processor = FaceProcessor()

    private var isUsingFrontCamera = false
    private var isCapturing = false

    private var currentFacePosition: FaceGuideOverlayView.FacePosition = .front
    private var faceImages: [FaceGuideOverlayView.FacePosition: UIImage] = [:]
    private let guideOverlayView = FaceGuideOverlayView()

    private var isFaceDetected = false
    // 화면에서 얼굴이 보이는지(ARKit 좌측 모드) 추적
    private var isFaceVisible: Bool = false
    private var countdownTimer: Timer?
    private var isCountingDownActive = false
    private var countdownCount = 0

    private var captureButton: UIButton!
    private var bottomLabel: UILabel!
    private var countdownLabel: UILabel?
    private var instructionLabel: UILabel?

    // 왼쪽 측면 안내 시각화 레이어 및 목표 요(yaw) 임계값
    private var currentYawLayer: CAShapeLayer?
    private var targetYawLayer: CAShapeLayer?
    private let leftTargetYaw: Float = -30 * Float.pi / 180  // 약 −30°
    // 오른쪽 측면 안내 시각화 레이어 및 목표 요(yaw) 임계값
    private var rightTargetYaw: Float = 30 * Float.pi / 180  // 약 +30°
    private var rightTargetX: CGFloat?
    private let yawThreshold: Float = 0.1       // 목표 요(yaw) 주변 허용 오차
    private var leftTargetX: CGFloat?


    // 뷰 로드 시 카메라 초기화 및 UI 요소 설정
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        // 카메라 배경 어둡게 처리
        let dimView = UIView(frame: view.bounds)
        dimView.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        dimView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(dimView)

        // 원형 컨테이너 안에 카메라 미리보기
        let cameraSize: CGFloat = min(view.bounds.width, view.bounds.height) * 0.9
        cameraContainer = UIView(frame: CGRect(
            x: (view.bounds.width - cameraSize) / 2,
            y: (view.bounds.height - cameraSize) / 2,
            width: cameraSize,
            height: cameraSize
        ))
        cameraContainer.layer.cornerRadius = cameraSize / 2
        cameraContainer.layer.masksToBounds = true
        cameraContainer.backgroundColor = .clear
        cameraContainer.autoresizingMask = [.flexibleLeftMargin, .flexibleRightMargin,
                                            .flexibleTopMargin, .flexibleBottomMargin]
        view.addSubview(cameraContainer)

        // 상단 안내 라벨 추가
        let topLabel = UILabel()
        topLabel.text = "얼굴 정면을 가이드 프레임 안에 맞춰주세요"
        topLabel.textColor = .white
        topLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        topLabel.translatesAutoresizingMaskIntoConstraints = false
        topLabel.tag = 1001
        view.addSubview(topLabel)
        NSLayoutConstraint.activate([
            topLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            topLabel.bottomAnchor.constraint(equalTo: cameraContainer.topAnchor, constant: -16)
        ])

        // ARKit 얼굴 트래킹으로 카메라 프리뷰 대체
        arView = ARSCNView(frame: cameraContainer.bounds)
        arView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        cameraContainer.addSubview(arView)

        let configuration = ARFaceTrackingConfiguration()
        configuration.isLightEstimationEnabled = true
        arView.session.delegate = self
        arView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])

        // 가이드 오버레이 뷰를 카메라 컨테이너에 추가하고 크기 맞춤
        guideOverlayView.frame = cameraContainer.bounds
        guideOverlayView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        cameraContainer.addSubview(guideOverlayView)
        guideOverlayView.currentPosition = currentFacePosition
        setupCaptureButton()

        // 촬영 준비 안내 라벨
        bottomLabel = UILabel()
        bottomLabel.text = "준비가 되면 아래 버튼을 눌러 촬영을 시작하세요"
        bottomLabel.textColor = .white
        bottomLabel.font = UIFont.systemFont(ofSize: 15)
        bottomLabel.textAlignment = .center
        bottomLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bottomLabel)
        NSLayoutConstraint.activate([
            bottomLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            bottomLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -110)
        ])
    }

    // 촬영 화면에서는 하단 탭바 숨기기
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.tabBar.isHidden = true
    }

    // 촬영 화면에서는 하단 탭바 숨기기
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        tabBarController?.tabBar.isHidden = false
    }


    // 촬영 버튼 UI 구성 및 눌렀을 때 행동 설정
    private func setupCaptureButton() {
        captureButton = UIButton(type: .system)
        captureButton.setTitle("촬영시작", for: .normal)
        captureButton.setTitleColor(.white, for: .normal)
        captureButton.backgroundColor = UIColor.systemGreen
        captureButton.layer.cornerRadius = 30
        captureButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(captureButton)

        NSLayoutConstraint.activate([
            captureButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            captureButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -40),
            captureButton.widthAnchor.constraint(equalToConstant: 60),
            captureButton.heightAnchor.constraint(equalToConstant: 60)
        ])

        captureButton.addTarget(self, action: #selector(handleManualCapture), for: .touchUpInside)
    }


    // 현재 얼굴 위치와 매칭되는 이미지를 저장 (임베딩은 나중에 일괄 처리)
    private func saveFaceImage(_ image: UIImage) {
        guard !isCapturing else { return }
        isCapturing = true
        faceImages[currentFacePosition] = image

        DispatchQueue.main.async {
            self.advanceToNextFacePosition()
            self.isCapturing = false
        }
    }

    // 다음 얼굴 위치로 전환, 모든 촬영이 완료되면 임베딩 추출 및 저장 진행
    private func advanceToNextFacePosition() {
//        print("촬영됨 \(currentFacePosition.description) face")

        if let next = FaceGuideOverlayView.FacePosition.allCases.first(where: { !faceImages.keys.contains($0) }) {
//            print("다음 촬영 이동 \(next.description)")
            currentFacePosition = next
            guideOverlayView.currentPosition = currentFacePosition
            if next == .left {
                // 정면 촬영이 끝난 직후 좌측 측면 진입 시 가이드 색상 초기화
                guideOverlayView.strokeColor = .red
                instructionLabel?.removeFromSuperview()
                instructionLabel = nil
                if let caution = view.viewWithTag(9001) {
                    caution.removeFromSuperview()
                }
                setupLeftMode()
            } else if next == .right {
                // 우측 측면 진입 시 가이드 색상 초기화 및 안내
                guideOverlayView.strokeColor = .red
                instructionLabel?.removeFromSuperview()
                instructionLabel = nil
                if let caution = view.viewWithTag(9001) {
                    caution.removeFromSuperview()
                }
                setupRightMode()
            } else {
                let alert = UIAlertController(title: "안내", message: "\(next.description)을(를) 촬영해주세요.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "확인", style: .default))
                present(alert, animated: true)
            }
        } else {
            saveAllVectors()
        }
    }
    // ARKit 얼굴 트래킹 안내를 사용하여 오른쪽 측면 촬영 UI 준비
    private func setupRightMode() {
        // AR 안내 이전에 초기 가이드 색상을 빨간색으로 설정
        guideOverlayView.strokeColor = .red
        // 즉시 촬영 버튼과 하단 라벨 숨기기
        captureButton.isHidden = true
        bottomLabel.isHidden = true
        instructionLabel?.removeFromSuperview()
        instructionLabel = nil
        if let caution = view.viewWithTag(9001) {
            caution.removeFromSuperview()
        }
        // 얼굴을 오른쪽으로 돌리도록 안내하는 라벨 표시
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
        // 얼굴이 화면 밖으로 나가면 안된다는 라벨 추가
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
        // AR 가이드 레이어를 오버레이하여 요(yaw) 시각화
        configureRightGuidanceLayers()
    }

    // 목표를 위한 세로 점선과 현재 위치를 위한 빈 실선 그리기 (오른쪽)
    private func configureRightGuidanceLayers() {
        cameraContainer.layoutIfNeeded()
        targetYawLayer?.removeFromSuperlayer()
        currentYawLayer?.removeFromSuperlayer()

        let containerBounds = cameraContainer.bounds

        // 계산: rightTargetYaw(+π/6)에서 +π/2(오른쪽 끝)까지 선형 매핑
        let fullRightYaw: Float = Float.pi / 2
        let normalizedTarget = rightTargetYaw / fullRightYaw // 0 to 1
        let targetX = containerBounds.midX + (containerBounds.width / 2) * CGFloat(normalizedTarget)

        // 점선 형태의 목표 위치(수직선)
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

        // 실선 형태의 현재 얼굴 위치 추적용 레이어(처음에는 아무 경로 없음)
        let currentLayer = CAShapeLayer()
        currentLayer.frame = containerBounds
        currentLayer.strokeColor = UIColor.white.cgColor
        currentLayer.lineWidth = 6
        currentLayer.fillColor = UIColor.clear.cgColor
        cameraContainer.layer.addSublayer(currentLayer)
        currentYawLayer = currentLayer
    }

    // 현재 얼굴 요(yaw)에 대한 세로 실선을 그리며, 코 팁 위치를 사용하여 실선 X좌표를 계산 (오른쪽)
    private func updateCurrentYawVisualizationRight(faceAnchor: ARFaceAnchor) {
        cameraContainer.layoutIfNeeded()
        guard let currentLayer = currentYawLayer, let targetX = rightTargetX else { return }

        let containerBounds = cameraContainer.bounds

        // 코 팁(코끝) landmark의 3D 좌표를 추출 (ARKit 기본 1220개 중 9번)
        let noseIndex = 9
        guard faceAnchor.geometry.vertices.count > noseIndex else { return }
        let noseVertex = faceAnchor.geometry.vertices[noseIndex]
        let noseWorldPosition = faceAnchor.transform * simd_float4(noseVertex.x, noseVertex.y, noseVertex.z, 1.0)
        // SCNVector3로 변환 후 화면 2D로 투영
        let nosePosition3D = SCNVector3(noseWorldPosition.x, noseWorldPosition.y, noseWorldPosition.z)
        let projectedNose = arView.projectPoint(nosePosition3D)
        let currentX = CGFloat(projectedNose.x)

        // 실선 경로 그리기 (곡선은 기존처럼 유지)
        let linePath = UIBezierPath()
        linePath.move(to: CGPoint(x: currentX - containerBounds.minX, y: 0))
        linePath.addLine(to: CGPoint(x: currentX - containerBounds.minX, y: containerBounds.height))
        currentLayer.path = linePath.cgPath

        // 기존 yaw 기반(좌우 이동 각도)은 유지 → 목표지점 proximity 비교 등은 이전 로직 그대로

        // 타겟 위치와의 픽셀 거리 계산
        let diffX = abs(currentX - targetX)
        let pixelThreshold: CGFloat = 10

        // 카운트다운 중일 때만 guideOverlayView.strokeColor를 green으로, 아니면 항상 빨간색 (측면 모드)
        if isCountingDownActive {
            guideOverlayView.strokeColor = .green
        } else {
            guideOverlayView.strokeColor = .red
        }

        if diffX < pixelThreshold && countdownTimer == nil {
            // 목표 지점에 도달하면 카운트다운 안내 표시 및 시작
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
            // countdownLabel이 없으면 생성하여 추가 (handleManualCapture와 유사)
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
            // 임계치 벗어나면 카운트다운 리셋
            resetCountdown()
        }
    }

    // ARKit 얼굴 트래킹 안내를 사용하여 왼쪽 측면 촬영 UI 준비
    private func setupLeftMode() {
        // AR 안내 이전에 초기 가이드 색상을 빨간색으로 설정
        guideOverlayView.strokeColor = .red
        // 즉시 촬영 버튼과 하단 라벨 숨기기
        captureButton.isHidden = true
        bottomLabel.isHidden = true
        instructionLabel?.removeFromSuperview()
        instructionLabel = nil
        if let caution = view.viewWithTag(9001) {
            caution.removeFromSuperview()
        }
        // 얼굴을 왼쪽으로 돌리도록 안내하는 라벨 표시
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
        // 얼굴이 화면 밖으로 나가면 안된다는 라벨 추가
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
        // AR 가이드 레이어를 오버레이하여 요(yaw) 시각화
        configureLeftGuidanceLayers()
    }

    // 목표를 위한 세로 점선과 현재 위치를 위한 빈 실선 그리기
    private func configureLeftGuidanceLayers() {
        cameraContainer.layoutIfNeeded()
        targetYawLayer?.removeFromSuperlayer()
        currentYawLayer?.removeFromSuperlayer()

        let containerBounds = cameraContainer.bounds

        // 계산: leftTargetYaw(-π/6)에서 -π/2(왼쪽 끝)까지 선형 매핑
        let fullLeftYaw: Float = -Float.pi / 2
        let normalizedTarget = leftTargetYaw / fullLeftYaw // 0 to 1
        let targetX = containerBounds.midX - (containerBounds.width / 2) * CGFloat(normalizedTarget)

        // 점선 형태의 목표 위치(수직선)
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

        // 실선 형태의 현재 얼굴 위치 추적용 레이어(처음에는 아무 경로 없음)
        let currentLayer = CAShapeLayer()
        currentLayer.frame = containerBounds
        currentLayer.strokeColor = UIColor.white.cgColor
        currentLayer.lineWidth = 6
        currentLayer.fillColor = UIColor.clear.cgColor
        cameraContainer.layer.addSublayer(currentLayer)
        currentYawLayer = currentLayer
    }

    // 현재 얼굴 요(yaw)에 대한 세로 실선을 그리며, 코 팁 위치를 사용하여 실선 X좌표를 계산
    private func updateCurrentYawVisualization(faceAnchor: ARFaceAnchor) {
        cameraContainer.layoutIfNeeded()
        guard let currentLayer = currentYawLayer, let targetX = leftTargetX else { return }

        let containerBounds = cameraContainer.bounds

        // 코 팁(코끝) landmark의 3D 좌표를 추출 (ARKit 기본 1220개 중 9번)
        let noseIndex = 9
        guard faceAnchor.geometry.vertices.count > noseIndex else { return }
        let noseVertex = faceAnchor.geometry.vertices[noseIndex]
        let noseWorldPosition = faceAnchor.transform * simd_float4(noseVertex.x, noseVertex.y, noseVertex.z, 1.0)
        // SCNVector3로 변환 후 화면 2D로 투영
        let nosePosition3D = SCNVector3(noseWorldPosition.x, noseWorldPosition.y, noseWorldPosition.z)
        let projectedNose = arView.projectPoint(nosePosition3D)
        let currentX = CGFloat(projectedNose.x)

        // 실선 경로 그리기 (곡선은 기존처럼 유지)
        let linePath = UIBezierPath()
        linePath.move(to: CGPoint(x: currentX - containerBounds.minX, y: 0))
        linePath.addLine(to: CGPoint(x: currentX - containerBounds.minX, y: containerBounds.height))
        currentLayer.path = linePath.cgPath

        // 기존 yaw 기반(좌우 이동 각도)은 유지 → 목표지점 proximity 비교 등은 이전 로직 그대로

        // 타겟 위치와의 픽셀 거리 계산
        let diffX = abs(currentX - targetX)
        let pixelThreshold: CGFloat = 10

        // 카운트다운 중일 때만 guideOverlayView.strokeColor를 green으로, 아니면 항상 빨간색 (측면 모드)
        if isCountingDownActive {
            guideOverlayView.strokeColor = .green
        } else {
            guideOverlayView.strokeColor = .red
        }

        if diffX < pixelThreshold && countdownTimer == nil {
            // 목표 지점에 도달하면 카운트다운 안내 표시 및 시작
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
            // countdownLabel이 없으면 생성하여 추가 (handleManualCapture와 유사)
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
            // 임계치 벗어나면 카운트다운 리셋
            resetCountdown()
        }
    }

    // 모든 얼굴 이미지에 대해 임베딩 벡터를 추출 후 Firestore에 일괄 저장
    private func saveAllVectors() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        var data: [String: [Float]] = [:]
        let group = DispatchGroup()

        for (position, image) in faceImages {
            if let buffer = image.pixelBuffer(width: 112, height: 112) {
                group.enter()
                processor?.extractFaceEmbedding(from: buffer) { vector in
                    if let vector = vector {
                        data["\(position.rawValue)_vector"] = vector
                    }
                    group.leave()
                }
            }
        }

        group.notify(queue: .main) {
            db.collection("users").document(uid).setData(data, merge: true)
            let alert = UIAlertController(title: "완료", message: "모든 얼굴 촬영이 완료되었습니다.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "확인", style: .default) { _ in
                if let docId = self.documentId {
                    db.collection("reserves").document(docId).updateData(["useFaceId": true]) { error in
                        if let error = error {
                            print("예약 문서 useFaceId 업데이트 실패: \(error)")
                        } else {
                            print("예약 문서 useFaceId 업데이트 성공")
                            NotificationCenter.default.post(name: NSNotification.Name("ReservationCancelled"), object: nil)
                        }
                    }
                }
                self.delegate?.faceCaptureDidFinish()
                self.navigationController?.popViewController(animated: true)
            })
            // 모든 촬영 완료 후 AR 세션 및 카메라 관련 기능 중지
            self.arView.session.pause()
            self.arView.scene.rootNode.childNodes.forEach { $0.removeFromParentNode() }
            self.arView.removeFromSuperview()
            self.captureButton?.isEnabled = false
            self.captureButton?.isHidden = true
            self.bottomLabel?.isHidden = true
            self.countdownLabel?.isHidden = true
            self.instructionLabel?.isHidden = true
            self.present(alert, animated: true)
        }
    }

    // 촬영 버튼 눌렀을 때 얼굴 인식 여부 확인 후 카운트다운 모드 진입
    @objc private func handleManualCapture() {
        // 얼굴이 인식되지 않은 경우 알림 후 종료
        if !isFaceDetected {
            let alert = UIAlertController(title: "얼굴 인식 필요", message: "프레임에 얼굴을 맞춰주세요.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "확인", style: .default))
            present(alert, animated: true)
            return
        }

        // 얼굴이 인식된 상태에서 버튼 누르면 카운트다운 모드 활성
        isCountingDownActive = true
        // 상단 안내 문구(얼굴 정면을 가이드 프레임 안에 맞춰주세요) 숨기기
        view.viewWithTag(1001)?.removeFromSuperview()

        // 버튼 및 하단 안내 라벨 숨기기
        captureButton.isHidden = true
        bottomLabel.isHidden = true

        // 상단 카운트다운 라벨 생성
        countdownLabel = UILabel()
        countdownLabel?.textColor = .white
        countdownLabel?.font = UIFont.systemFont(ofSize: 60, weight: .bold)
        countdownLabel?.textAlignment = .center
        countdownLabel?.translatesAutoresizingMaskIntoConstraints = false
        if let countdownLabel = countdownLabel {
            view.addSubview(countdownLabel)
            NSLayoutConstraint.activate([
                // 카운트다운 숫자를 카메라 컨테이너 바로 위에 위치시키기
                countdownLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                countdownLabel.bottomAnchor.constraint(equalTo: cameraContainer.topAnchor, constant: -16)
            ])
        }

        // 하단 촬영 안내 라벨 생성 (초기 안내 문구)
        instructionLabel = UILabel()
        instructionLabel?.text = "3초 후 자동으로 촬영됩니다"
        instructionLabel?.textColor = .white
        instructionLabel?.font = UIFont.systemFont(ofSize: 15)
        instructionLabel?.textAlignment = .center
        instructionLabel?.translatesAutoresizingMaskIntoConstraints = false
        if let instructionLabel = instructionLabel {
            view.addSubview(instructionLabel)
            NSLayoutConstraint.activate([
                instructionLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                instructionLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -110)
            ])
        }

        // 3초 카운트다운 시작
        startCountdown()
    }

    // 카운트다운 시작
    private func startCountdown() {
        countdownCount = 3
        countdownLabel?.text = "\(countdownCount)"
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self = self else { return }
            self.countdownCount -= 1
            if self.countdownCount > 0 {
                self.countdownLabel?.text = "\(self.countdownCount)"
            } else {
                timer.invalidate()
                self.countdownTimer = nil
                // 카운트다운 완료 후 사진 촬영
                self.countdownLabel?.removeFromSuperview()
                self.instructionLabel?.removeFromSuperview()
                self.countdownLabel = nil
                self.instructionLabel = nil
                self.isCountingDownActive = false
                self.capturePhoto()
            }
        }
    }

    // 카운트다운 리셋 (중단 및 재설정)
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

    // 카운트다운 후 사진 촬영 및 저장
    private func capturePhoto() {
        guard let currentFrame = arView.session.currentFrame else { return }
        let pixelBuffer = currentFrame.capturedImage

        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext()
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return }
        let image = UIImage(cgImage: cgImage)
        saveFaceImage(image)
    }

    // MARK: - ARSessionDelegate (AR 세션 델리게이트)
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        // 좌측/우측 모드인 경우 ARFaceAnchor를 사용하여 실시간 위치 계산
        if currentFacePosition == .left || currentFacePosition == .right {
            let faceAnchor = frame.anchors.compactMap { $0 as? ARFaceAnchor }.first
            if let faceAnchor = faceAnchor {
                DispatchQueue.main.async {
                    // 얼굴 중심 3D 좌표를 2D 화면 좌표로 변환
                    let node = SCNNode()
                    node.simdTransform = faceAnchor.transform
                    let projectedPoint = self.arView.projectPoint(node.position)
                    let projectedCGPoint = CGPoint(x: CGFloat(projectedPoint.x), y: CGFloat(projectedPoint.y))
                    let center = CGPoint(x: self.cameraContainer.bounds.midX, y: self.cameraContainer.bounds.midY)
                    let radius = min(self.cameraContainer.bounds.width, self.cameraContainer.bounds.height) / 2
                    let dx = projectedCGPoint.x - center.x
                    let dy = projectedCGPoint.y - center.y
                    let distance = sqrt(dx*dx + dy*dy)
                    let isInsideCircle = distance < radius * 0.9 // 여유값

                    if !self.isFaceVisible || isInsideCircle != self.isFaceVisible {
                        self.isFaceVisible = isInsideCircle
                        if isInsideCircle {
                            self.currentYawLayer?.isHidden = false
                            self.targetYawLayer?.strokeColor = UIColor.white.withAlphaComponent(0.7).cgColor
                        } else {
                            self.currentYawLayer?.isHidden = true
                            self.targetYawLayer?.strokeColor = UIColor.red.cgColor
                        }
                    }
                    if isInsideCircle {
                        if self.currentFacePosition == .left {
                            self.updateCurrentYawVisualization(faceAnchor: faceAnchor)
                        } else if self.currentFacePosition == .right {
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
        // 그렇지 않으면 Vision 기반 정면 얼굴 검증 사용
        let pixelBuffer = frame.capturedImage
        validateFrontFace(on: pixelBuffer)
    }

    // Vision 얼굴 검증 로직을 ARKit 프레임에 맞게 분리
    private func validateFrontFace(on pixelBuffer: CVPixelBuffer) {
        // 현재 얼굴 위치에 따라 guideRect 정의 (UIKit 좌표계)
        let guideRectInView: CGRect
        switch currentFacePosition {
        case .front:
            guideRectInView = CGRect(x: view.bounds.midX - 150,
                                     y: view.bounds.midY - 140,
                                     width: 300,
                                     height: 280)
        case .left:
            guideRectInView = CGRect(x: view.bounds.midX - 200,
                                     y: view.bounds.midY - 140,
                                     width: 310,
                                     height: 280)
        case .right:
            guideRectInView = CGRect(x: view.bounds.midX - 110,
                                     y: view.bounds.midY - 140,
                                     width: 310,
                                     height: 280)
        }


        // UIKit의 guideRect를 Vision의 정규화된 regionOfInterest 좌표로 변환
        let normalizedX      = guideRectInView.origin.x / view.bounds.width
        let normalizedY      = (view.bounds.height - guideRectInView.origin.y - guideRectInView.height) / view.bounds.height
        let normalizedWidth  = guideRectInView.width / view.bounds.width
        let normalizedHeight = guideRectInView.height / view.bounds.height

        let normalizedGuideRect = CGRect(x: normalizedX,
                                         y: normalizedY,
                                         width: normalizedWidth,
                                         height: normalizedHeight)

        // 디버깅: orientation 파라미터 추가(.leftMirrored 확인) 및 regionOfInterest 임시 주석 처리
        let orientation: CGImagePropertyOrientation = .leftMirrored
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer,
                                            orientation: orientation,
                                            options: [:])
        if currentFacePosition == .front {
            // 정면 모드: 랜드마크(눈, 코, 입) 검출을 시도하여 가이드 영역 내 여부를 확인
            let landmarksRequest = VNDetectFaceLandmarksRequest { [weak self] request, error in
                guard let self = self else { return }

                // 랜드마크 검출이 성공하고 얼굴이 인식된 경우
                if let observations = request.results as? [VNFaceObservation],
                   let observation = observations.first,
                   let landmarks = observation.landmarks {

                    // 인식된 얼굴 boundingBox를 뷰 좌표로 변환하고, 랜드마크 좌표를 뷰 좌표로 매핑
                    let faceRect = VNImageRectForNormalizedRect(
                        observation.boundingBox,
                        Int(self.view.bounds.width),
                        Int(self.view.bounds.height)
                    )

                    let guideRect: CGRect
                    switch self.currentFacePosition {
                    case .front:
                        guideRect = CGRect(x: self.view.bounds.midX - 150,
                                           y: self.view.bounds.midY - 140,
                                           width: 300, height: 280)
                    case .left:
                        guideRect = CGRect(x: self.view.bounds.midX - 200,
                                           y: self.view.bounds.midY - 140,
                                           width: 310, height: 280)
                    case .right:
                        guideRect = CGRect(x: self.view.bounds.midX - 110,
                                           y: self.view.bounds.midY - 140,
                                           width: 310, height: 280)
                    }

                    func convertLandmarkPoint(_ pt: CGPoint) -> CGPoint {
                        let x = faceRect.origin.x + pt.x * faceRect.width
                        let y = self.view.bounds.height - (faceRect.origin.y + pt.y * faceRect.height)
                        return CGPoint(x: x, y: y)
                    }

                    // 분리하여 복잡한 map 체인을 나눔
                    var leftEyePoints: [CGPoint] = []
                    if let leftEyeNorm = landmarks.leftEye?.normalizedPoints {
                        leftEyePoints = leftEyeNorm.map(convertLandmarkPoint)
                    }

                    var rightEyePoints: [CGPoint] = []
                    if let rightEyeNorm = landmarks.rightEye?.normalizedPoints {
                        rightEyePoints = rightEyeNorm.map(convertLandmarkPoint)
                    }

                    var nosePoints: [CGPoint] = []
                    if let noseNorm = landmarks.nose?.normalizedPoints {
                        nosePoints = noseNorm.map(convertLandmarkPoint)
                    }

                    var mouthPoints: [CGPoint] = []
                    if let outerNorm = landmarks.outerLips?.normalizedPoints {
                        mouthPoints = outerNorm.map(convertLandmarkPoint)
                    } else if let innerNorm = landmarks.innerLips?.normalizedPoints {
                        mouthPoints = innerNorm.map(convertLandmarkPoint)
                    }

                    // 각 랜드마크(왼쪽 눈, 오른쪽 눈, 코, 입) 점 개수 기준 검증
                    let hasLeftEye = leftEyePoints.count >= 3
                    let hasRightEye = rightEyePoints.count >= 3
                    let hasNose = nosePoints.count >= 3
                    let hasMouth = mouthPoints.count >= 3

                    // 랜드마크 점들의 중심 좌표(centroid) 계산 함수
                    func centroid(of points: [CGPoint]) -> CGPoint {
                        let sum = points.reduce(CGPoint.zero) { CGPoint(x: $0.x + $1.x, y: $0.y + $1.y) }
                        return CGPoint(x: sum.x / CGFloat(points.count), y: sum.y / CGFloat(points.count))
                    }

                    // 모든 랜드마크 중심이 가이드 박스 내부에 있는지 검증
                    var landmarksInsideGuide = false
                    if hasLeftEye, hasRightEye, hasNose, hasMouth {
                        let leftEyeCenter = centroid(of: leftEyePoints)
                        let rightEyeCenter = centroid(of: rightEyePoints)
                        let noseCenter = centroid(of: nosePoints)
                        let mouthCenter = centroid(of: mouthPoints)
                        landmarksInsideGuide = guideRect.contains(leftEyeCenter) &&
                                               guideRect.contains(rightEyeCenter) &&
                                               guideRect.contains(noseCenter) &&
                                               guideRect.contains(mouthCenter)
                    }

                    // 가이드 영역 겹침 비율, 얼굴 크기, 랜드마크 내부 여부 모두 확인하여 유효한 얼굴인지 판단
                    let intersection = guideRect.intersection(faceRect)
                    let intersectionArea = intersection.width * intersection.height
                    let faceArea = faceRect.width * faceRect.height
                    let heightRatio = intersection.height / faceRect.height

                    // 위치에 따라 다른 임계값 사용(정면)
                    let areaThreshold: CGFloat = 0.65
                    let heightThreshold: CGFloat = 0.65
                    let isWithinGuideArea = faceArea > 0 && (intersectionArea / faceArea > areaThreshold)
                    let isWithinGuideHeight = heightRatio > heightThreshold

                    let minFaceWidth: CGFloat  = 140
                    let minFaceHeight: CGFloat = 90
                    let isFaceLargeEnough = faceRect.width >= minFaceWidth && faceRect.height >= minFaceHeight

                    let isValidFace = landmarksInsideGuide && isWithinGuideArea && isWithinGuideHeight && isFaceLargeEnough

                    DispatchQueue.main.async {
                        self.guideOverlayView.strokeColor = isValidFace ? .green : .red
                        let previousFaceDetected = self.isFaceDetected
                        self.isFaceDetected = isValidFace

                        if self.isCountingDownActive {
                            if self.isFaceDetected {
                                // 안내문구 즉시 갱신 또는 생성
                                if let label = self.instructionLabel, label.superview != nil {
                                    label.text = "3초 후 자동으로 촬영됩니다"
                                } else {
                                    let newInstructionLabel = UILabel()
                                    newInstructionLabel.text = "3초 후 자동으로 촬영됩니다"
                                    newInstructionLabel.textColor = .white
                                    newInstructionLabel.font = UIFont.systemFont(ofSize: 15)
                                    newInstructionLabel.textAlignment = .center
                                    newInstructionLabel.translatesAutoresizingMaskIntoConstraints = false
                                    self.instructionLabel = newInstructionLabel
                                    self.view.addSubview(newInstructionLabel)
                                    NSLayoutConstraint.activate([
                                        newInstructionLabel.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
                                        newInstructionLabel.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor, constant: -110)
                                    ])
                                }
                                if self.countdownTimer == nil {
                                    self.countdownTimer?.invalidate()
                                    self.countdownTimer = nil
                                    self.countdownLabel?.removeFromSuperview()
                                    self.startCountdown()
                                }
                            } else {
                                // 얼굴 해제시 안내문구 새로 생성
                                if self.countdownTimer != nil {
                                    self.resetCountdown()
                                }
                                self.instructionLabel?.removeFromSuperview()
                                let newInstructionLabel = UILabel()
                                newInstructionLabel.text = "얼굴 정면을 가이드 프레임 안에 맞춰주세요"
                                newInstructionLabel.textColor = .white
                                newInstructionLabel.font = UIFont.systemFont(ofSize: 15)
                                newInstructionLabel.textAlignment = .center
                                newInstructionLabel.translatesAutoresizingMaskIntoConstraints = false
                                self.instructionLabel = newInstructionLabel
                                self.view.addSubview(newInstructionLabel)
                                NSLayoutConstraint.activate([
                                    newInstructionLabel.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
                                    newInstructionLabel.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor, constant: -110)
                                ])
                            }
                        }
                    }
                } else {
                    // 사이드(측면) 모드 또는 랜드마크 검출 실패 시 사각형 기반 얼굴 검출로 대체
                    let rectRequest = VNDetectFaceRectanglesRequest { [weak self] req, err in
                        guard let self = self else { return }
                        guard let observations = req.results as? [VNFaceObservation],
                              let observation = observations.first else {
                            DispatchQueue.main.async {
                            self.guideOverlayView.strokeColor = .red
                            self.isFaceDetected = false
                            // 카운트다운 활성 상태에서 얼굴 인식 변화 처리
                            if self.isCountingDownActive {
                                if self.isFaceDetected {
                                    // 얼굴이 인식되고 카운트다운이 진행 중이지 않다면 안내 문구 변경 후 카운트다운 시작
                                    if self.countdownTimer == nil {
                                        self.instructionLabel?.removeFromSuperview()
                                        self.instructionLabel = UILabel()
                                        self.instructionLabel?.text = "얼굴이 가이드 프레임 안에 들어오면 자동으로 촬영됩니다"
                                        self.instructionLabel?.textColor = .white
                                        self.instructionLabel?.font = UIFont.systemFont(ofSize: 15)
                                        self.instructionLabel?.textAlignment = .center
                                        self.instructionLabel?.translatesAutoresizingMaskIntoConstraints = false
                                        if let instructionLabel = self.instructionLabel {
                                            self.view.addSubview(instructionLabel)
                                            NSLayoutConstraint.activate([
                                                instructionLabel.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
                                                instructionLabel.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor, constant: -110)
                                            ])
                                        }
                                        self.startCountdown()
                                    }
                                } else {
                                    if self.countdownTimer != nil {
                                        self.resetCountdown()
                                    }
                                }
                            }
                            }
                            return
                        }

                        // 탐지된 boundingBox를 뷰 좌표로 변환
                        let faceRect = VNImageRectForNormalizedRect(
                            observation.boundingBox,
                            Int(self.view.bounds.width),
                            Int(self.view.bounds.height)
                        )

                        let guideRect: CGRect
                        switch self.currentFacePosition {
                        case .front:
                            guideRect = CGRect(x: self.view.bounds.midX - 150,
                                               y: self.view.bounds.midY - 140,
                                               width: 280, height: 280)
                        case .left:
                            guideRect = CGRect(x: self.view.bounds.midX - 200,
                                               y: self.view.bounds.midY - 140,
                                               width: 310, height: 280)
                        case .right:
                            guideRect = CGRect(x: self.view.bounds.midX - 110,
                                               y: self.view.bounds.midY - 140,
                                               width: 310, height: 280)
                        }

                        // 위치에 따라 다른 임계값 사용 (정면)
                        let intersection = guideRect.intersection(faceRect)
                        let intersectionArea = intersection.width * intersection.height
                        let faceArea = faceRect.width * faceRect.height
                        let heightRatio = intersection.height / faceRect.height

                        let areaThreshold: CGFloat = 0.65
                        let heightThreshold: CGFloat = 0.65
                        let isWithinGuideArea = faceArea > 0 && (intersectionArea / faceArea > areaThreshold)
                        let isWithinGuideHeight = heightRatio > heightThreshold

                        let minFaceWidth: CGFloat = 140
                        let minFaceHeight: CGFloat = 90
                        let isFaceLargeEnough = faceRect.width >= minFaceWidth && faceRect.height >= minFaceHeight

                        let isValidFace = isWithinGuideArea && isWithinGuideHeight && isFaceLargeEnough

                        DispatchQueue.main.async {
                            self.guideOverlayView.strokeColor = isValidFace ? .green : .red
                            self.isFaceDetected = isValidFace
                            // 카운트다운 활성 상태에서 얼굴 인식 변화 처리
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
                    try? handler.perform([rectRequest])
                }
            }
            landmarksRequest.regionOfInterest = normalizedGuideRect
            try? handler.perform([landmarksRequest])
        } else {
            // 사이드(측면) 모드 또는 랜드마크 검출 실패 시 사각형 기반 얼굴 검출로 대체
            let rectRequest = VNDetectFaceRectanglesRequest { [weak self] req, err in
                guard let self = self else { return }
                guard let observations = req.results as? [VNFaceObservation],
                      let observation = observations.first else {
                    DispatchQueue.main.async {
                        self.guideOverlayView.strokeColor = .red
                        self.isFaceDetected = false
                        // 카운트다운 활성 상태에서 얼굴 인식 변화 처리
                        if self.isCountingDownActive {
                            if self.isFaceDetected {
                                // 얼굴이 인식되고 카운트다운이 진행 중이지 않다면 안내 문구 변경 후 카운트다운 시작
                                if self.countdownTimer == nil {
                                    self.instructionLabel?.removeFromSuperview()
                                    self.instructionLabel = UILabel()
                                    self.instructionLabel?.text = "얼굴이 가이드 프레임 안에 들어오면 자동으로 촬영됩니다"
                                    self.instructionLabel?.textColor = .white
                                    self.instructionLabel?.font = UIFont.systemFont(ofSize: 15)
                                    self.instructionLabel?.textAlignment = .center
                                    self.instructionLabel?.translatesAutoresizingMaskIntoConstraints = false
                                    if let instructionLabel = self.instructionLabel {
                                        self.view.addSubview(instructionLabel)
                                        NSLayoutConstraint.activate([
                                            instructionLabel.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
                                            instructionLabel.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor, constant: -110)
                                        ])
                                    }
                                    self.startCountdown()
                                }
                            } else {
                                if self.countdownTimer != nil {
                                    self.resetCountdown()
                                }
                            }
                        }
                    }
                    return
                }

                // 탐지된 boundingBox를 뷰 좌표로 변환
                let faceRect = VNImageRectForNormalizedRect(
                    observation.boundingBox,
                    Int(self.view.bounds.width),
                    Int(self.view.bounds.height)
                )

                let guideRect: CGRect
                switch self.currentFacePosition {
                case .front:
                    guideRect = CGRect(x: self.view.bounds.midX - 150,
                                       y: self.view.bounds.midY - 140,
                                       width: 300, height: 280)
                case .left:
                    guideRect = CGRect(x: self.view.bounds.midX - 200,
                                       y: self.view.bounds.midY - 140,
                                       width: 310, height: 280)
                case .right:
                    guideRect = CGRect(x: self.view.bounds.midX - 110,
                                       y: self.view.bounds.midY - 140,
                                       width: 310, height: 280)
                }

                // 위치에 따라 다른 임계값 사용 (정면)
                let intersection = guideRect.intersection(faceRect)
                let intersectionArea = intersection.width * intersection.height
                let faceArea = faceRect.width * faceRect.height
                let heightRatio = intersection.height / faceRect.height

                let areaThreshold: CGFloat = 0.65
                let heightThreshold: CGFloat = 0.65
                let isWithinGuideArea = faceArea > 0 && (intersectionArea / faceArea > areaThreshold)
                let isWithinGuideHeight = heightRatio > heightThreshold

                let minFaceWidth: CGFloat = 140
                let minFaceHeight: CGFloat = 90
                let isFaceLargeEnough = faceRect.width >= minFaceWidth && faceRect.height >= minFaceHeight

                let isValidFace = isWithinGuideArea && isWithinGuideHeight && isFaceLargeEnough

                DispatchQueue.main.async {
                    self.guideOverlayView.strokeColor = isValidFace ? .green : .red
                    self.isFaceDetected = isValidFace
                    // 카운트다운 활성 상태에서 얼굴 인식 변화 처리
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
            try? handler.perform([rectRequest])
        }
    }
}
