//
//  FaceCaptureViewController.swift
//  FaceInn
//
//  Created by CHOI on 5/23/25.
//

// 카메라 세션 초기화
// 사용 기술: AVFoundation

import UIKit
import AVFoundation
import Vision
import FirebaseFirestore
import FirebaseAuth


final class FaceCaptureViewController: UIViewController {
    weak var delegate: FaceCaptureDelegate?
    var shouldDismissToRoot: Bool = false
    var documentId: String?
    // 카메라 원형 컨테이너 뷰 참조용 프로퍼티
    private var cameraContainer: UIView!
    // 카메라 세션 및 출력 처리, 얼굴 임베딩 추출을 위한 관련 변수들
    private var captureSession: AVCaptureSession!
    private var videoOutput: AVCaptureVideoDataOutput!
    private var previewLayer: AVCaptureVideoPreviewLayer!
    private var captureQueue = DispatchQueue(label: "captureQueue")
    private var processor = FaceProcessor()

    private var isUsingFrontCamera = false
    private var isCapturing = false
    private let switchCameraButton: UIButton = {
        let button = UIButton(type: .system)
        let image = UIImage(systemName: "arrow.triangle.2.circlepath.camera")
        button.setImage(image, for: .normal)
        button.tintColor = .white
        button.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        button.layer.cornerRadius = 25
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private var currentFacePosition: FaceGuideOverlayView.FacePosition = .front
    private var faceImages: [FaceGuideOverlayView.FacePosition: UIImage] = [:]
    private let guideOverlayView = FaceGuideOverlayView()

    private var isFaceDetected = false
    private var currentSampleBuffer: CMSampleBuffer?
    private var countdownTimer: Timer?
    private var isCountingDownActive = false
    private var countdownCount = 0

    private var captureButton: UIButton!
    private var bottomLabel: UILabel!
    private var countdownLabel: UILabel?
    private var instructionLabel: UILabel?

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

        // 컨테이너 뷰 안에 카메라 프리뷰 레이어 배치
        setupCamera()
        previewLayer.frame = cameraContainer.bounds
        cameraContainer.layer.insertSublayer(previewLayer, at: 0)

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

    // AVFoundation을 사용해 카메라 입력 및 출력 설정
    private func setupCamera() {
        captureSession = AVCaptureSession()
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              let input = try? AVCaptureDeviceInput(device: device) else { return }

        captureSession.beginConfiguration()
        if captureSession.canAddInput(input) { captureSession.addInput(input) }

        videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: captureQueue)
        if captureSession.canAddOutput(videoOutput) { captureSession.addOutput(videoOutput) }

        captureSession.commitConfiguration()

        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill

        // previewLayer.frame: viewDidLoad에서 cameraContainer에 삽입

        captureSession.startRunning()
    }

    // 카메라 전후면 전환 버튼 UI 구성 및 동작 설정
    private func setupSwitchCameraButton(captureButton: UIButton) {
        view.addSubview(switchCameraButton)
        NSLayoutConstraint.activate([
            switchCameraButton.centerYAnchor.constraint(equalTo: captureButton.centerYAnchor),
            switchCameraButton.leadingAnchor.constraint(equalTo: captureButton.trailingAnchor, constant: 20),
            switchCameraButton.widthAnchor.constraint(equalToConstant: 50),
            switchCameraButton.heightAnchor.constraint(equalToConstant: 50)
        ])
        switchCameraButton.addTarget(self, action: #selector(toggleCamera), for: .touchUpInside)
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

        setupSwitchCameraButton(captureButton: captureButton)
    }

    @objc private func toggleCamera() {
        isUsingFrontCamera.toggle()
        captureSession.stopRunning()
        captureSession.inputs.forEach { captureSession.removeInput($0) }

        let position: AVCaptureDevice.Position = isUsingFrontCamera ? .front : .back
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position),
              let input = try? AVCaptureDeviceInput(device: device) else { return }

        captureSession.beginConfiguration()
        if captureSession.canAddInput(input) {
            captureSession.addInput(input)
        }
        captureSession.commitConfiguration()
        captureSession.startRunning()
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
        print("촬영됨 \(currentFacePosition.description) face")

        if let next = FaceGuideOverlayView.FacePosition.allCases.first(where: { !faceImages.keys.contains($0) }) {
            print("다음 촬영 이동 \(next.description)")
            currentFacePosition = next
            guideOverlayView.currentPosition = currentFacePosition

            let alert = UIAlertController(title: "안내", message: "\(next.description)을(를) 촬영해주세요.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "확인", style: .default))
            present(alert, animated: true)
        } else {
            print("촬영 완료")
            captureSession.stopRunning()
            saveAllVectors()
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
        switchCameraButton.isHidden = true
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
        instructionLabel?.text = "얼굴이 가이드 프레임 안에 들어오면 자동으로 촬영됩니다"
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
        // 카운트다운 모드는 여전히 활성 상태로 유지
        isCountingDownActive = true
        // 안내 라벨: 얼굴을 가이드 프레임 안에 맞춰달라는 문구
        instructionLabel = UILabel()
        instructionLabel?.text = "얼굴 정면을 가이드 프레임 안에 맞춰주세요"
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
    }

    // 카운트다운 후 사진 촬영 및 저장
    private func capturePhoto() {
        guard let sampleBuffer = currentSampleBuffer,
              let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        let ciImage = CIImage(cvImageBuffer: pixelBuffer)
        let context = CIContext()
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return }
        let image = UIImage(cgImage: cgImage)
        saveFaceImage(image)
    }
}

extension FaceCaptureViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    // 카메라 실시간 출력에서 얼굴 인식 여부 판단하여 프레임 색상 변경 (중앙 가이드 내에 얼굴이 있는지 확인)
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

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

                    let leftEyePoints = landmarks.leftEye?.normalizedPoints.map(convertLandmarkPoint) ?? []
                    let rightEyePoints = landmarks.rightEye?.normalizedPoints.map(convertLandmarkPoint) ?? []
                    let nosePoints = landmarks.nose?.normalizedPoints.map(convertLandmarkPoint) ?? []
                    let mouthPoints = (landmarks.outerLips?.normalizedPoints.map(convertLandmarkPoint)) ??
                                      (landmarks.innerLips?.normalizedPoints.map(convertLandmarkPoint)) ?? []

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

                    // 위치에 따라 다른 임계값 사용 (정면은 더 엄격, 측면은 완화)
                    let areaThreshold: CGFloat = (self.currentFacePosition == .front) ? 0.40 : 0.30
                    let heightThreshold: CGFloat = (self.currentFacePosition == .front) ? 0.45 : 0.30
                    let isWithinGuideArea = faceArea > 0 && (intersectionArea / faceArea > areaThreshold)
                    let isWithinGuideHeight = heightRatio > heightThreshold

                    let minFaceWidth: CGFloat  = 50
                    let minFaceHeight: CGFloat = 80
                    let isFaceLargeEnough = faceRect.width >= minFaceWidth && faceRect.height >= minFaceHeight

                    let isValidFace = landmarksInsideGuide && isWithinGuideArea && isWithinGuideHeight && isFaceLargeEnough

                    DispatchQueue.main.async {
                        self.view.viewWithTag(999)?.removeFromSuperview()
                        let debugRect = CGRect(x: guideRect.origin.x, y: guideRect.origin.y,
                                               width: guideRect.width, height: guideRect.height)
                        let debugView = UIView(frame: debugRect)
                        debugView.layer.borderWidth = 2
                        debugView.layer.borderColor = UIColor.yellow.cgColor
                        debugView.backgroundColor = .clear
                        debugView.tag = 999
                        self.view.addSubview(debugView)

                        self.guideOverlayView.strokeColor = isValidFace ? .green : .red
                        self.isFaceDetected = isValidFace
                        // 카운트다운 활성 상태에서 얼굴 인식 변화 처리
                        if self.isCountingDownActive {
                            if self.isFaceDetected {
                                // 얼굴이 인식되고 카운트다운이 진행 중이지 않다면 안내 문구 변경 후 카운트다운 시작
                                if self.countdownTimer == nil {
                                    self.instructionLabel?.removeFromSuperview()
                                    self.instructionLabel = UILabel()
                                    self.instructionLabel?.text = "3초 후 자동으로 촬영됩니다"
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
                                // 얼굴이 인식되지 않으면 카운트다운 중단 및 리셋
                                if self.countdownTimer != nil {
                                    self.resetCountdown()
                                }
                            }
                        }
                        if isValidFace {
                            self.currentSampleBuffer = sampleBuffer
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

                        // 위치에 따라 다른 임계값 사용 (정면은 더 엄격, 측면은 완화)
                        let intersection = guideRect.intersection(faceRect)
                        let intersectionArea = intersection.width * intersection.height
                        let faceArea = faceRect.width * faceRect.height
                        let heightRatio = intersection.height / faceRect.height

                        let areaThreshold: CGFloat = (self.currentFacePosition == .front) ? 0.75 : 0.45
                        let heightThreshold: CGFloat = (self.currentFacePosition == .front) ? 0.6 : 0.4
                        let isWithinGuideArea = faceArea > 0 && (intersectionArea / faceArea > areaThreshold)
                        let isWithinGuideHeight = heightRatio > heightThreshold

                        let minFaceWidth: CGFloat = 85
                        let minFaceHeight: CGFloat = 120
                        let isFaceLargeEnough = faceRect.width >= minFaceWidth && faceRect.height >= minFaceHeight

                        let isValidFace = isWithinGuideArea && isWithinGuideHeight && isFaceLargeEnough

                        DispatchQueue.main.async {
                            self.view.viewWithTag(999)?.removeFromSuperview()
                            let debugRect = CGRect(x: guideRect.origin.x, y: guideRect.origin.y,
                                                   width: guideRect.width, height: guideRect.height)
                            let debugView = UIView(frame: debugRect)
                            debugView.layer.borderWidth = 2
                            debugView.layer.borderColor = UIColor.yellow.cgColor
                            debugView.backgroundColor = .clear
                            debugView.tag = 999
                            self.view.addSubview(debugView)

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
                            if isValidFace {
                                self.currentSampleBuffer = sampleBuffer
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

                // 위치에 따라 다른 임계값 사용 (정면은 더 엄격, 측면은 완화)
                let intersection = guideRect.intersection(faceRect)
                let intersectionArea = intersection.width * intersection.height
                let faceArea = faceRect.width * faceRect.height
                let heightRatio = intersection.height / faceRect.height

                let areaThreshold: CGFloat = (self.currentFacePosition == .front) ? 0.75 : 0.45
                let heightThreshold: CGFloat = (self.currentFacePosition == .front) ? 0.6 : 0.4
                let isWithinGuideArea = faceArea > 0 && (intersectionArea / faceArea > areaThreshold)
                let isWithinGuideHeight = heightRatio > heightThreshold

                let minFaceWidth: CGFloat = 85
                let minFaceHeight: CGFloat = 120
                let isFaceLargeEnough = faceRect.width >= minFaceWidth && faceRect.height >= minFaceHeight

                let isValidFace = isWithinGuideArea && isWithinGuideHeight && isFaceLargeEnough

                DispatchQueue.main.async {
                    self.view.viewWithTag(999)?.removeFromSuperview()
                    let debugRect = CGRect(x: guideRect.origin.x, y: guideRect.origin.y,
                                           width: guideRect.width, height: guideRect.height)
                    let debugView = UIView(frame: debugRect)
                    debugView.layer.borderWidth = 2
                    debugView.layer.borderColor = UIColor.yellow.cgColor
                    debugView.backgroundColor = .clear
                    debugView.tag = 999
                    self.view.addSubview(debugView)

                    self.guideOverlayView.strokeColor = isValidFace ? .green : .red
                    self.isFaceDetected = isValidFace
                    if isValidFace {
                        self.currentSampleBuffer = sampleBuffer
                    }
                }
            }
            try? handler.perform([rectRequest])
        }
    }
}
