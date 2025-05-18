//
//   AccommodationSeeder.swift
//  FaceInn
//
//  Created by 신찬솔 on 5/18/25.
//

import UIKit
import FirebaseFirestore
import FirebaseStorage

struct AccommodationSeeder {
    static func seedShillaHotel(docId: String = "shilla") {
        let accommodationId = docId
        let docRef = Firestore.firestore().collection("accommodations").document(accommodationId)

        let data: [String: Any] = [
            "name": "신라호텔",
            "location": "서울 중구 동호로 249",
            "rating": 4.8,
            "reviewCount": 1523,
            "description": "서울 중심에 위치한 고급 호텔로 아름다운 시티뷰와 다양한 편의시설을 갖추고 있습니다.",
            "amenities": ["Wi-Fi", "수영장", "피트니스 센터", "무료 주차", "레스토랑", "룸서비스"],
            "hostId": "host_shilla",
            "imageURLs": [
                "https://firebasestorage.googleapis.com/v0/b/faceinn-9c609.firebasestorage.app/o/shilla1.jpg?alt=media&token=a8e07efd-6290-4011-9e4a-7133d0ab662e",
                "https://firebasestorage.googleapis.com/v0/b/faceinn-9c609.firebasestorage.app/o/shilla2.jpg?alt=media&token=b66311f4-6e9a-4566-b75f-e46fbc0fc031",
                "https://firebasestorage.googleapis.com/v0/b/faceinn-9c609.firebasestorage.app/o/shilla3.jpg?alt=media&token=ac1c0db7-c67b-421c-b10b-f7f6c1ffbc42",
                "https://firebasestorage.googleapis.com/v0/b/faceinn-9c609.firebasestorage.app/o/shilla4.jpg?alt=media&token=274a9f0c-69ec-41b4-a77b-1eeb6a13d5b5"
            ],
            "rooms": [
                [
                    "id": "room1",
                    "name": "디럭스 시티뷰",
                    "price": 300000,
                    "maxOccupancy": 2,
                    "checkInTime": "15:00",
                    "checkOutTime": "11:00",
                    "description": "서울 도심 전망의 고급 디럭스룸입니다.",
                    "imageURLs": ["https://firebasestorage.googleapis.com/v0/b/faceinn-9c609.firebasestorage.app/o/shillaRoom1.jpg?alt=media&token=20509c5d-04ff-4556-bd33-e58dcdeab4e3"],
                    "amenities": ["Wi-Fi", "TV", "욕조", "냉장고"]
                ],
                [
                    "id": "room2",
                    "name": "프리미엄 스위트",
                    "price": 600000,
                    "maxOccupancy": 4,
                    "checkInTime": "15:00",
                    "checkOutTime": "11:00",
                    "description": "럭셔리한 분위기의 프리미엄 스위트룸입니다.",
                    "imageURLs": ["https://firebasestorage.googleapis.com/v0/b/faceinn-9c609.firebasestorage.app/o/shillaRoom2.jpg?alt=media&token=f0a474f0-1b11-40e7-91a0-3de09d85c49b"],
                    "amenities": ["Wi-Fi", "TV", "욕조", "미니바", "거실"]
                ]
            ]
        ]

        docRef.setData(data) { error in
            if let error = error {
                print("❌ Firestore 저장 실패: \(error.localizedDescription)")
            } else {
                print("✅ 신라호텔 데이터 저장 성공")
            }
        }
    }
}
