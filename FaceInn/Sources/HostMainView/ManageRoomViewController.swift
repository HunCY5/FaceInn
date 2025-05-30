//
//  ManageRoomViewController.swift
//  FaceInn
//
//  Created by CHOI on 5/28/25.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore


final class ManageRoomViewController: UIViewController{
    private var tableView: UITableView!
    private var rooms: [AccommodationRoom] = []
    
    private let statusStack = UIStackView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // "객실 현황" 라벨
        let titleLabel = UILabel()
        titleLabel.text = "객실 현황"
        titleLabel.font = UIFont.boldSystemFont(ofSize: 22)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)
        
        let addButton = UIButton(type: .system)
        addButton.setTitle("객실추가", for: .normal)
        addButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        addButton.translatesAutoresizingMaskIntoConstraints = false
        addButton.setTitleColor(UIColor(red: 47/255, green: 175/255, blue: 83/255, alpha: 1), for: .normal)
        view.addSubview(addButton)
        
        addButton.addTarget(self, action: #selector(didTapAddRoom), for: .touchUpInside)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            addButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            addButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ])

        setupStatusSummary()

        // 객실 목록 TableView placeholder
        tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: statusStack.bottomAnchor, constant: 16),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
        
        tableView.register(RoomTableViewCell.self, forCellReuseIdentifier: "RoomCell")
        tableView.dataSource = self
        
        fetchRooms()
    }
    
    private func fetchRooms() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        db.collection("users").document(uid).getDocument { snapshot, error in
            guard let data = snapshot?.data(), let accommodationId = data["accommodationId"] as? String else { return }
            db.collection("accommodations").document(accommodationId).addSnapshotListener { snap, err in
                guard let docData = snap?.data(), let roomDicts = docData["rooms"] as? [[String: Any]] else {
                    self.rooms = []
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                        self.updateStatusCounts()
                    }
                    return
                }
                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: roomDicts)
                    self.rooms = try JSONDecoder().decode([AccommodationRoom].self, from: jsonData)
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                        self.updateStatusCounts()
                    }
                } catch {
                    print("Failed to decode rooms: \(error)")
                }
            }
        }
    }

    private func createStatusBox(count: String, title: String, bgColor: UIColor, textColor: UIColor) -> UIView {
        let container = UIView()
        container.backgroundColor = bgColor
        container.layer.cornerRadius = 8
        container.translatesAutoresizingMaskIntoConstraints = false

        let countLabel = UILabel()
        countLabel.text = count
        countLabel.font = UIFont.boldSystemFont(ofSize: 18)
        countLabel.textColor = textColor
        countLabel.textAlignment = .center

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 12)
        titleLabel.textColor = .darkGray
        titleLabel.textAlignment = .center

        let stack = UIStackView(arrangedSubviews: [countLabel, titleLabel])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 4
        stack.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])

        return container
    }

    private func setupStatusSummary() {
        statusStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        let availableBox = createStatusBox(count: "0", title: "가능",
            bgColor: UIColor(red: 0.94, green: 1, blue: 0.94, alpha: 1),
            textColor: UIColor(red: 0.2, green: 0.6, blue: 0.3, alpha: 1))
        let checkedInBox = createStatusBox(count: "0", title: "투숙",
            bgColor: UIColor(red: 1.0, green: 0.94, blue: 0.94, alpha: 1),
            textColor: .systemRed)
        let reservedBox = createStatusBox(count: "0", title: "예약",
            bgColor: UIColor(red: 0.94, green: 0.96, blue: 1.0, alpha: 1),
            textColor: .systemBlue)

        availableBox.tag = 1
        checkedInBox.tag = 2
        reservedBox.tag = 3

        statusStack.axis = .horizontal
        statusStack.distribution = .fillEqually
        statusStack.spacing = 12
        statusStack.translatesAutoresizingMaskIntoConstraints = false

        statusStack.addArrangedSubview(availableBox)
        statusStack.addArrangedSubview(checkedInBox)
        statusStack.addArrangedSubview(reservedBox)

        view.addSubview(statusStack)

        NSLayoutConstraint.activate([
            statusStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 76),
            statusStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            statusStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            statusStack.heightAnchor.constraint(equalToConstant: 60)
        ])
    }

    private func updateStatusCounts() {
        var available = 0
        var reserved = 0
        var checkedIn = 0

        let db = Firestore.firestore()
        guard let hostId = Auth.auth().currentUser?.uid else { return }

        db.collection("reserves").whereField("hostId", isEqualTo: hostId).addSnapshotListener { snapshot, _ in
            let today = Calendar.current.startOfDay(for: Date())

            available = 0
            reserved = 0
            checkedIn = 0

            for room in self.rooms {
                var status: String = "예약가능"

                if let docs = snapshot?.documents {
                    for doc in docs {
                        let data = doc.data()
                        guard let roomName = data["roomName"] as? String,
                              roomName == room.name,
                              let start = data["startDate"] as? Timestamp,
                              let end = data["endDate"] as? Timestamp,
                              let isCheckIn = data["checkIn"] as? Bool else { continue }

                        let startDate = Calendar.current.startOfDay(for: start.dateValue())
                        let endDate = Calendar.current.startOfDay(for: end.dateValue()).addingTimeInterval(86400)

                        if today >= startDate && today < endDate {
                            status = isCheckIn ? "투숙중" : "예약"
                            break
                        }
                    }
                }

                switch status {
                case "예약": reserved += 1
                case "투숙중": checkedIn += 1
                default: available += 1
                }
            }

            DispatchQueue.main.async {
                if let availableBox = self.statusStack.viewWithTag(1) as? UIView,
                   let countLabel = availableBox.subviews.first?.subviews.first as? UILabel {
                    countLabel.text = "\(available)"
                }
                if let checkedInBox = self.statusStack.viewWithTag(2) as? UIView,
                   let countLabel = checkedInBox.subviews.first?.subviews.first as? UILabel {
                    countLabel.text = "\(checkedIn)"
                }
                if let reservedBox = self.statusStack.viewWithTag(3) as? UIView,
                   let countLabel = reservedBox.subviews.first?.subviews.first as? UILabel {
                    countLabel.text = "\(reserved)"
                }
            }
        }
    }
    
    @objc private func didTapAddRoom() {
        let registerVC = RoomRegisterViewController()
        registerVC.hidesBottomBarWhenPushed = true
        self.navigationController?.pushViewController(registerVC, animated: true)
    }
}

extension ManageRoomViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rooms.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "RoomCell", for: indexPath) as? RoomTableViewCell else {
            return UITableViewCell()
        }
        let room = rooms[indexPath.row]
        if let hostId = Auth.auth().currentUser?.uid {
            cell.configure(with: room, hostId: hostId)
        }
        cell.selectionStyle = .none
        return cell
    }
}
