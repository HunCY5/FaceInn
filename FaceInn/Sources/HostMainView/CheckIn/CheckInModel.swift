//
//  CheckInModel.swift
//  FaceInn
//
//  Created by CHOI on 6/2/25.
//

import UIKit

// MARK: - StatItem (통계 항목)
struct StatItem {
    let title: String
    let value: String
    let iconName: String
    let iconTintColor: UIColor
}

// MARK: - RecentRecognition (최근 인식 결과)
struct RecentRecognition {
    enum Mode {
        case checkin, checkout
    }
    let guestName: String
    let roomNumber: String
    let mode: Mode
    let time: String
}
