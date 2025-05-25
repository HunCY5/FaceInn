//
//  FaceProcessor.swift
//  FaceInn
//
//  Created by CHOI on 5/24/25.
//

// 얼굴 감지
// 사용 기술: Vision, CoreML

import UIKit
import Vision
import CoreML

final class FaceProcessor {
    // CoreML로 변환된 MobileFaceNet 모델을 Vision에 로딩
    private let model: VNCoreMLModel

    init?() {
        guard let visionModel = try? VNCoreMLModel(for: MobileFaceNet(configuration: MLModelConfiguration()).model) else {
            print("모델 로딩 실패")
            return nil
        }
        self.model = visionModel
    }

    // 입력된 픽셀 버퍼 이미지로부터 얼굴 임베딩 벡터 추출
    func extractFaceEmbedding(from pixelBuffer: CVPixelBuffer, completion: @escaping ([Float]?) -> Void) {
        let request = VNCoreMLRequest(model: model) { request, error in
            guard let results = request.results as? [VNCoreMLFeatureValueObservation],
                  let multiArray = results.first?.featureValue.multiArrayValue else {
                print("벡터 추출 실패")
                completion(nil)
                return
            }
            let floatArray = (0..<multiArray.count).map { Float(truncating: multiArray[$0]) }
            completion(floatArray)
        }

        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        DispatchQueue.global().async {
            do {
                try handler.perform([request])
            } catch {
                print("Vision 요청 실패: \(error.localizedDescription)")
                completion(nil)
            }
        }
    }

    // Vision을 사용해 이미지에서 얼굴 위치를 감지
    func detectFaceRectangles(in pixelBuffer: CVPixelBuffer, completion: @escaping ([VNFaceObservation]) -> Void) {
        let request = VNDetectFaceRectanglesRequest { request, error in
            guard let observations = request.results as? [VNFaceObservation], error == nil else {
                print("얼굴 감지 실패")
                completion([])
                return
            }
            completion(observations)
        }

        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        DispatchQueue.global().async {
            do {
                try handler.perform([request])
            } catch {
                print("얼굴 감지 요청 실패: \(error.localizedDescription)")
                completion([])
            }
        }
    }
}
