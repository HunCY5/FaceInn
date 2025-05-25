//
//  UIImage+PixelBuffer.swift
//  FaceInn
//
//  Created by CHOI on 5/24/25.
//

// UIImage를 CoreML 모델 입력으로 사용할 수 있는 CVPixelBuffer 형태로 변환해주는 확장 메서드

import UIKit

extension UIImage {
    func pixelBuffer(width: Int, height: Int) -> CVPixelBuffer? {
        // 픽셀 버퍼 생성 시 필요한 호환성 속성 정의
        let attrs = [kCVPixelBufferCGImageCompatibilityKey: true,
                     kCVPixelBufferCGBitmapContextCompatibilityKey: true] as CFDictionary
        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(kCFAllocatorDefault, width, height,
                                         kCVPixelFormatType_32ARGB, attrs, &pixelBuffer)
        guard status == kCVReturnSuccess, let buffer = pixelBuffer else {
            return nil
        }

        // 픽셀 버퍼 주소를 잠금 후 Core Graphics 컨텍스트 생성
        CVPixelBufferLockBaseAddress(buffer, [])
        let context = CGContext(data: CVPixelBufferGetBaseAddress(buffer),
                                width: width,
                                height: height,
                                bitsPerComponent: 8,
                                bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
                                space: CGColorSpaceCreateDeviceRGB(),
                                bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)

        // 픽셀 버퍼 주소를 잠금 후 Core Graphics 컨텍스트 생성
        if let cgImage = self.cgImage {
            context?.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        }

        // 픽셀 버퍼 주소를 잠금 후 Core Graphics 컨텍스트 생성
        CVPixelBufferUnlockBaseAddress(buffer, [])
        return buffer
    }
}
