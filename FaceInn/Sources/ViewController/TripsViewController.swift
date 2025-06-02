//
//  TripsViewController.swift
//  FaceInn
//
//  Created by 신찬솔 on 5/18/25.
//

import UIKit
import FirebaseFirestore
import FirebaseAuth
import Kingfisher

final class TripsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    private let segmentControl: UISegmentedControl = {
        let sc = UISegmentedControl(items: ["이용전", "이용후"])
        sc.selectedSegmentIndex = 0
        sc.translatesAutoresizingMaskIntoConstraints = false
        return sc
    }()
    private var selectedTab: Int = 0
    private var selectedReservations: [[String: Any]] {
        return selectedTab == 0 ? upcomingReservations : pastReservations
    }

    private var upcomingReservations: [[String: Any]] = []
    private var pastReservations: [[String: Any]] = []
    private let tableView = UITableView()
    
    private let emptyLabel: UILabel = {
        let label = UILabel()
        label.text = "예약 내역이 없습니다."
        label.textColor = .lightGray
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isHidden = true
        return label
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "여행"
        view.backgroundColor = .white
        view.addSubview(segmentControl)
        NSLayoutConstraint.activate([
            segmentControl.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            segmentControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            segmentControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ])
        segmentControl.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)
        setupTableView()
        view.addSubview(emptyLabel)
        NSLayoutConstraint.activate([
            emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        fetchReservations()
        NotificationCenter.default.addObserver(self, selector: #selector(handleReservationCancelled), name: NSNotification.Name("ReservationCancelled"), object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchReservations()
    }

    private func setupTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(ReservationCell.self, forCellReuseIdentifier: "Cell")
        tableView.allowsSelection = false
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: segmentControl.bottomAnchor, constant: 8),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }

    private func fetchReservations() {
        guard let user = Auth.auth().currentUser else {
            self.upcomingReservations = []
            self.pastReservations = []
            DispatchQueue.main.async {
                self.tableView.reloadData()
                self.updateEmptyLabelText()
            }
            return
        }
        let db = Firestore.firestore()
        db.collection("reserves").whereField("userId", isEqualTo: user.uid).getDocuments { snapshot, error in
            guard let documents = snapshot?.documents, error == nil else {
                print("예약 정보를 불러오지 못했습니다:", error?.localizedDescription ?? "알 수 없음")
                return
            }
            let now = Date()
            var upcoming: [[String: Any]] = []
            var past: [[String: Any]] = []
            for doc in documents {
                var data = doc.data()
                data["documentId"] = doc.documentID
                if let end = (data["endDate"] as? Timestamp)?.dateValue(), end > now {
                    upcoming.append(data)
                } else {
                    past.append(data)
                }
            }
            self.upcomingReservations = upcoming.sorted {
                let date1 = ($0["startDate"] as? Timestamp)?.dateValue() ?? Date.distantFuture
                let date2 = ($1["startDate"] as? Timestamp)?.dateValue() ?? Date.distantFuture
                return date1 < date2
            }
            self.pastReservations = past.sorted {
                let date1 = ($0["endDate"] as? Timestamp)?.dateValue() ?? Date.distantPast
                let date2 = ($1["endDate"] as? Timestamp)?.dateValue() ?? Date.distantPast
                return date1 > date2
            }
            DispatchQueue.main.async {
                self.tableView.reloadData()
                self.updateEmptyLabelText()
            }
        }
    }

    private func updateEmptyLabelText() {
        if selectedTab == 0 {
            emptyLabel.text = "예약 내역이 없습니다."
            emptyLabel.isHidden = !upcomingReservations.isEmpty
        } else {
            emptyLabel.text = "이용 내역이 없습니다."
            emptyLabel.isHidden = !pastReservations.isEmpty
        }
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return selectedReservations.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as? ReservationCell else {
            return UITableViewCell()
        }

        let reservation = selectedReservations[indexPath.row]
        cell.titleLabel.text = reservation["accommodationName"] as? String ?? "숙소명 없음"
        let startDate = (reservation["startDate"] as? Timestamp)?.dateValue()
        let endDate = (reservation["endDate"] as? Timestamp)?.dateValue()
        let nights = reservation["numberOfNights"] as? Int ?? 1
        cell.subtitleLabel.text = "\(reservation["roomName"] as? String ?? "객실명 없음") • \(nights)박"

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M.d (E) HH:mm"
        let checkIn = (reservation["startDate"] as? Timestamp)?.dateValue().addingTimeInterval(60 * 60 * 15)
        let checkOut = (reservation["endDate"] as? Timestamp)?.dateValue().addingTimeInterval(60 * 60 * 11)
        cell.checkInDateLabel.text = checkIn.map { formatter.string(from: $0) } ?? "-"
        cell.checkOutDateLabel.text = checkOut.map { formatter.string(from: $0) } ?? "-"

        if let imageURL = reservation["imageURL"] as? String, let url = URL(string: imageURL) {
            cell.thumbnailImageView.kf.setImage(with: url, placeholder: UIImage(named: "placeholder"))
        } else {
            cell.thumbnailImageView.image = UIImage(named: "placeholder")
        }

        if let reserveNumber = reservation["reserveNumber"] as? Int {
            cell.faceIdStatusLabel.text = "예약번호: \(reserveNumber)"
        } else {
            cell.faceIdStatusLabel.text = "예약번호 없음"
        }

        cell.showCancelButton(selectedTab == 0)
        cell.documentId = reservation["documentId"] as? String
        // 얼굴인식 토글 스위치 설정
        let useFaceId = reservation["useFaceId"] as? Bool ?? false
        cell.faceToggleSwitch.setOn(useFaceId, animated: false)
        cell.faceToggleSwitch.isHidden = (selectedTab == 1)
        cell.faceToggleLabel.isHidden = (selectedTab == 1)
        return cell
    }


    @objc private func segmentChanged(_ sender: UISegmentedControl) {
        selectedTab = sender.selectedSegmentIndex
        tableView.reloadData()
        updateEmptyLabelText()
    }

    @objc private func handleReservationCancelled() {
        fetchReservations()
    }
}
