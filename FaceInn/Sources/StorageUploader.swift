//
//  StorageUploader.swift
//  FaceInn
//
//  Created by 신찬솔 on 5/18/25.
//

import Foundation
import FirebaseStorage
import FirebaseFirestore

final class StorageUploader {
    
    // 숙소 이미지 여러 개를 등록하는 함수
    static func uploadAccommodationImages(accommodationId: String, imageNames: [String]) {
        for name in imageNames {
            let refPath = "accommodationImages/\(name)"
            getDownloadURL(for: refPath) { url in
                if let url = url {
                    saveImageURLToAccommodation(accommodationId: accommodationId, imageURL: url)
                }
            }
        }
    }
    
    // 특정 파일 이름으로 Storage URL 받아오기
    private static func getDownloadURL(for path: String, completion: @escaping (String?) -> Void) {
        let ref = Storage.storage().reference().child(path)
        ref.downloadURL { url, error in
            if let error = error {
                print("❌ URL 가져오기 실패 (\(path)): \(error.localizedDescription)")
                completion(nil)
            } else {
                print("✅ URL 가져오기 성공 (\(path)): \(url!.absoluteString)")
                completion(url?.absoluteString)
            }
        }
    }
    
    // 숙소 문서에 imageURLs 필드에 추가 저장
    private static func saveImageURLToAccommodation(accommodationId: String, imageURL: String) {
        let docRef = Firestore.firestore().collection("accommodations").document(accommodationId)
        docRef.updateData([
            "imageURLs": FieldValue.arrayUnion([imageURL])
        ]) { error in
            if let error = error {
                print("❌ Firestore 저장 실패: \(error.localizedDescription)")
            } else {
                print("✅ Firestore 저장 성공 (숙소 \(accommodationId))")
            }
        }
    }
}
