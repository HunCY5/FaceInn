//
//  Accommodation.swift
//  FaceInn
//
//  Created by 신찬솔 on 5/18/25.
//

import Foundation

struct Accommodation {
    let id: String
    let name: String
    let location: String
    let price: Int
    let rating: Double
    let reviewCount: Int
    let imageURLs: [String]?
    let rooms: [[String: Any]]?
    var amenities: [String]?
    var description: String?
    let hostId: String?
    var filteredRooms: [[String: Any]]? {
        guard let rooms = rooms else { return nil }
        let guestCount = UserDefaults.standard.integer(forKey: "selectedGuestCount")
        return rooms.filter {
            if let maxOccupancy = $0["maxOccupancy"] as? Int {
                return maxOccupancy >= guestCount
            }
            return false
        }
    }
}
