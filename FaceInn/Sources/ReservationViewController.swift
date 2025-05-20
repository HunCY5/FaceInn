//
//  ReservationViewController.swift
//  FaceInn
//
//  Created by 신찬솔 on 5/21/25.
//


import UIKit

final class ReservationViewController: UIViewController {
    
    var accommodation: Accommodation?
    var room: AccommodationRoom?
    var startDate: Date?
    var endDate: Date?
    var guestCount: Int?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        title = "예약"

        assert(accommodation != nil, "❌ accommodation 정보가 nil입니다.")
        assert(room != nil, "❌ room 정보가 nil입니다.")
        print("✅ 예약 정보 수신 확인 - 숙소명: \(accommodation?.name ?? "nil"), 객실명: \(room?.name ?? "nil")")

        let label = UILabel()
        label.numberOfLines = 0
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false

        if let accommodation = accommodation,
           let room = room,
           let startDate = UserDefaults.standard.object(forKey: "selectedStartDate") as? Date,
           let endDate = UserDefaults.standard.object(forKey: "selectedEndDate") as? Date {

            let calendar = Calendar.current
            let numberOfNights = calendar.dateComponents([.day], from: startDate, to: endDate).day ?? 1
            let totalPrice = room.price * numberOfNights
            let formattedTotal = totalPrice.formattedWithSeparator
            let guestCount = UserDefaults.standard.integer(forKey: "selectedGuestCount")

            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy년 M월 d일"
            let dateRange = "\(formatter.string(from: startDate)) - \(formatter.string(from: endDate))"

            label.text = """
             \(accommodation.name)
             \(room.name)
             \(dateRange)
             \(numberOfNights)박
             ₩\(formattedTotal)
             \(guestCount)명
            """
        } else {
            label.text = "예약 페이지"
        }

        view.addSubview(label)

        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
}

private extension Int {
    var formattedWithSeparator: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }
}
