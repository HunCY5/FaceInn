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

    // 뷰 로드 시 카메라 초기화 및 UI 요소 설정
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupCamera()
        view.addSubview(guideOverlayView)
        guideOverlayView.frame = view.bounds
        guideOverlayView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        guideOverlayView.currentPosition = currentFacePosition
        setupCaptureButton()
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
        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device) else { return }

        captureSession.beginConfiguration()
        if captureSession.canAddInput(input) { captureSession.addInput(input) }

        videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: captureQueue)
        if captureSession.canAddOutput(videoOutput) { captureSession.addOutput(videoOutput) }

        captureSession.commitConfiguration()

        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.bounds
        view.layer.insertSublayer(previewLayer, at: 0)

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
        let button = UIButton(type: .system)
        button.setTitle("촬영", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor.systemGreen
        button.layer.cornerRadius = 30
        button.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(button)

        NSLayoutConstraint.activate([
            button.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            button.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -40),
            button.widthAnchor.constraint(equalToConstant: 60),
            button.heightAnchor.constraint(equalToConstant: 60)
        ])

        button.addTarget(self, action: #selector(handleManualCapture), for: .touchUpInside)

        setupSwitchCameraButton(captureButton: button)
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

    // 촬영 버튼 눌렀을 때 현재 얼굴이 감지되었는지 확인 후 이미지 저장
    @objc private func handleManualCapture() {
        if !isFaceDetected {
            let alert = UIAlertController(title: "얼굴 인식 필요", message: "프레임에 얼굴을 맞춰주세요.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "확인", style: .default))
            present(alert, animated: true)
            return
        }

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
    // 카메라 실시간 출력에서 얼굴 인식 여부 판단하여 프레임 색상 변경
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        let request = VNDetectFaceRectanglesRequest { [weak self] req, err in
            guard let self = self,
                  let observations = req.results as? [VNFaceObservation],
                  observations.first != nil else {
                DispatchQueue.main.async {
                    self?.guideOverlayView.strokeColor = .red
                    self?.isFaceDetected = false
                }
                return
            }
            DispatchQueue.main.async {
                self.guideOverlayView.strokeColor = .green
                self.isFaceDetected = true
                self.currentSampleBuffer = sampleBuffer
            }
        }
        try? handler.perform([request])
    }
}
