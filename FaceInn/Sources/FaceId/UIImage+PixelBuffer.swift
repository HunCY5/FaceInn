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
        // 픽셀 버퍼 생성 시 필요한 호환성 속성 정의 (sRGB, BGRA, iOSurface)
        let attrs: [String: Any] = [
            kCVPixelBufferCGImageCompatibilityKey as String: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey as String: true,
            kCVPixelBufferIOSurfacePropertiesKey as String: [:]
        ]
        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(kCFAllocatorDefault,
                                         width,
                                         height,
                                         kCVPixelFormatType_32BGRA, // 표준 BGRA 포맷
                                         attrs as CFDictionary,
                                         &pixelBuffer)
        guard status == kCVReturnSuccess, let buffer = pixelBuffer else {
            return nil
        }

        // UIImage.orientation을 반영한 소스 CGImage 생성 (왜곡/회전/미러링 보정)
        let srcSize = self.size
        let orientedImage = UIGraphicsImageRenderer(size: srcSize).image { _ in
            self.draw(in: CGRect(origin: .zero, size: srcSize))
        }
        guard let srcCG = orientedImage.cgImage else { return nil }

        // 픽셀 버퍼에 직접 그리기: sRGB 색공간 + BGRA 비트맵 설정
        CVPixelBufferLockBaseAddress(buffer, [])
        defer { CVPixelBufferUnlockBaseAddress(buffer, []) }

        guard let baseAddress = CVPixelBufferGetBaseAddress(buffer) else { return nil }
        let bytesPerRow = CVPixelBufferGetBytesPerRow(buffer)
        let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue

        guard let context = CGContext(data: baseAddress,
                                      width: width,
                                      height: height,
                                      bitsPerComponent: 8,
                                      bytesPerRow: bytesPerRow,
                                      space: colorSpace,
                                      bitmapInfo: bitmapInfo) else { return nil }

        // Aspect-Fill(센터 크롭): 종횡비 유지, 모자라는 쪽은 잘라서 채우기
        let srcW = CGFloat(srcCG.width)
        let srcH = CGFloat(srcCG.height)
        let dstW = CGFloat(width)
        let dstH = CGFloat(height)
        let scale = max(dstW / srcW, dstH / srcH)
        let drawW = srcW * scale
        let drawH = srcH * scale
        let drawX = (dstW - drawW) * 0.5
        let drawY = (dstH - drawH) * 0.5
        let drawRect = CGRect(x: drawX, y: drawY, width: drawW, height: drawH)

        // 배경 초기화(선택): 투명/검정 등 필요 시 활성화
        // context.clear(CGRect(x: 0, y: 0, width: width, height: height))

        context.draw(srcCG, in: drawRect)
        return buffer
    }

    /// 얼굴 박스 등 소스 이미지의 특정 영역을 잘라 표준화된 PixelBuffer로 변환합니다.
    /// - Parameters:
    ///   - cropRect: **오리엔트가 반영된** 소스 CGImage 좌표계 기반의 픽셀 단위 사각형
    ///   - width: 타깃 너비(예: 112)
    ///   - height: 타깃 높이(예: 112)
    ///   - aspectFill: true면 타깃 비율에 맞춰 센터 크롭(권장), false면 비율 왜곡 허용
    /// - Returns: BGRA/sRGB 포맷의 CVPixelBuffer
    func pixelBuffer(cropRect: CGRect, width: Int, height: Int, aspectFill: Bool = true) -> CVPixelBuffer? {
        // 픽셀 버퍼 준비 (BGRA, sRGB)
        let attrs: [String: Any] = [
            kCVPixelBufferCGImageCompatibilityKey as String: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey as String: true,
            kCVPixelBufferIOSurfacePropertiesKey as String: [:]
        ]
        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(kCFAllocatorDefault,
                                         width,
                                         height,
                                         kCVPixelFormatType_32BGRA,
                                         attrs as CFDictionary,
                                         &pixelBuffer)
        guard status == kCVReturnSuccess, let buffer = pixelBuffer else { return nil }

        // UIImage.orientation을 반영한 CGImage(오리엔트 적용)
        let srcSize = self.size
        let oriented = UIGraphicsImageRenderer(size: srcSize).image { _ in
            self.draw(in: CGRect(origin: .zero, size: srcSize))
        }
        guard let fullCG = oriented.cgImage else { return nil }

        // cropRect는 오리엔트 반영된 fullCG 좌표 기준이어야 함
        guard let croppedCG = fullCG.cropping(to: cropRect.integral) else { return nil }

        CVPixelBufferLockBaseAddress(buffer, [])
        defer { CVPixelBufferUnlockBaseAddress(buffer, []) }
        guard let base = CVPixelBufferGetBaseAddress(buffer) else { return nil }
        let bytesPerRow = CVPixelBufferGetBytesPerRow(buffer)
        let cs = CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue
        guard let ctx = CGContext(data: base,
                                  width: width,
                                  height: height,
                                  bitsPerComponent: 8,
                                  bytesPerRow: bytesPerRow,
                                  space: cs,
                                  bitmapInfo: bitmapInfo) else { return nil }

        let srcW = CGFloat(croppedCG.width)
        let srcH = CGFloat(croppedCG.height)
        let dstW = CGFloat(width)
        let dstH = CGFloat(height)

        let drawRect: CGRect
        if aspectFill {
            // Aspect-Fill: 비율 유지 + 중앙 크롭(권장)
            let scale = max(dstW / srcW, dstH / srcH)
            let drawW = srcW * scale
            let drawH = srcH * scale
            drawRect = CGRect(x: (dstW - drawW) * 0.5,
                              y: (dstH - drawH) * 0.5,
                              width: drawW,
                              height: drawH)
        } else {
            // 비율 왜곡 허용 (일부 모델에서 필요할 수 있음)
            drawRect = CGRect(x: 0, y: 0, width: dstW, height: dstH)
        }

        ctx.draw(croppedCG, in: drawRect)
        return buffer
    }
}
