//
//  Reservation.swift
//  FaceInn
//
//  Created by 신찬솔 on 5/30/25.
//

import Foundation

struct Reservation {
    let id: String
    let userName: String
    let phone: String
    let roomName: String
    let price: Int
    let startDate: Date
    let endDate: Date
    let reserveNumber: Int
    let useFaceId: Bool
    let checkIn: Bool?
}
