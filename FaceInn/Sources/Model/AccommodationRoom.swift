//
//  Room.swift
//  FaceInn
//
//  Created by 신찬솔 on 5/21/25.
//



import Foundation

struct AccommodationRoom: Codable, Equatable {
    let id: String
    var name: String
    let description: String
    let price: Int
    let maxOccupancy: Int
    let imageURLs: [String]
    let checkInTime: String
    let checkOutTime: String
    let amenities: [String]
}
