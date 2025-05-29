//
//  ManageReservationViewController.swift
//  FaceInn
//
//  Created by CHOI on 5/28/25.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

final class ManageReservationViewController: UIViewController, UISearchBarDelegate {
    
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

    private var reservations: [Reservation] = []
    private var filteredReservations: [Reservation] = []
    private let stackView = UIStackView()
    private let scrollView = UIScrollView()
    
    private let dateSelectButton: UIButton = {
        let button = UIButton(type: .system)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy년 MM월 dd일"
        let today = formatter.string(from: Date())
        button.setTitle(today, for: .normal)
        button.setTitleColor(UIColor(red: 0x2f/255, green: 0xaf/255, blue: 0x53/255, alpha: 1), for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        button.backgroundColor = .white
        button.layer.borderColor = UIColor.lightGray.cgColor
        button.layer.borderWidth = 1
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        self.applyDefaultDateFilter()

        let titleLabel = UILabel()
        titleLabel.text = "예약 현황"
        titleLabel.font = UIFont.boldSystemFont(ofSize: 22)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)

        let searchBar = UISearchBar()
        searchBar.placeholder = "고객명 또는 객실번호 검색"
        searchBar.delegate = self
        searchBar.searchBarStyle = .minimal
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(searchBar)

        stackView.axis = .vertical
        stackView.spacing = 16

        // 날짜 선택 버튼
        view.addSubview(dateSelectButton)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        scrollView.addSubview(stackView)

        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),

            searchBar.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            dateSelectButton.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 12),
            dateSelectButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            dateSelectButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            dateSelectButton.heightAnchor.constraint(equalToConstant: 40),

            scrollView.topAnchor.constraint(equalTo: dateSelectButton.bottomAnchor, constant: 20),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -20),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -40)
        ])
        dateSelectButton.addTarget(self, action: #selector(presentDatePicker), for: .touchUpInside)
        fetchReservations()
    }
    
    private func fetchReservations() {
        guard let hostId = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        db.collection("reserves").whereField("hostId", isEqualTo: hostId).addSnapshotListener { snapshot, error in
            guard let documents = snapshot?.documents else { return }
            self.reservations.removeAll()
            let group = DispatchGroup()
            for doc in documents {
                group.enter()
                let data = doc.data()
                let userId = data["userId"] as? String ?? ""
                db.collection("users").document(userId).getDocument { userDoc, _ in
                    defer { group.leave() }
                    let userData = userDoc?.data()
                    let name = userData?["name"] as? String ?? "알 수 없음"
                    let phone = userData?["phoneNumber"] as? String ?? "-"
                    let roomName = data["roomName"] as? String ?? ""
                    let price = data["totalPrice"] as? Int ?? 0
                    let startDate = (data["startDate"] as? Timestamp)?.dateValue() ?? Date()
                    let endDate = (data["endDate"] as? Timestamp)?.dateValue() ?? Date()
                    let reserveNumber = data["reserveNumber"] as? Int ?? 0
                    let useFaceId = data["useFaceId"] as? Bool ?? false
                    let checkIn = data["checkIn"] as? Bool
                    let reservation = Reservation(id: doc.documentID, userName: name, phone: phone, roomName: roomName, price: price, startDate: startDate, endDate: endDate, reserveNumber: reserveNumber, useFaceId: useFaceId, checkIn: checkIn)
                    self.reservations.append(reservation)
                }
            }
            group.notify(queue: .main) {
                self.reloadFilteredReservations()
            }
        }
    }
    
    private func addReservationView(_ reservation: Reservation) {
        let container = UIView()
        container.layer.borderColor = UIColor.lightGray.cgColor
        container.layer.borderWidth = 1
        container.layer.cornerRadius = 8
        container.translatesAutoresizingMaskIntoConstraints = false

        // 이름, 예약번호
        let nameLabel = UILabel()
        nameLabel.text = reservation.userName
        nameLabel.font = UIFont.boldSystemFont(ofSize: 14)

        let reservationNumberLabel = UILabel()
        reservationNumberLabel.text = "예약번호: \(reservation.reserveNumber)"
        reservationNumberLabel.font = UIFont.systemFont(ofSize: 12)
        reservationNumberLabel.textColor = .gray

        let topStack = UIStackView(arrangedSubviews: [nameLabel, reservationNumberLabel])
        topStack.axis = .vertical
        topStack.alignment = .leading
        topStack.spacing = 2

        // 객실 / 금액
        let roomTitle = UILabel()
        roomTitle.text = "객실"
        roomTitle.font = UIFont.systemFont(ofSize: 12)
        roomTitle.textColor = .gray

        let roomLabel = UILabel()
        roomLabel.text = reservation.roomName
        roomLabel.font = UIFont.boldSystemFont(ofSize: 14)

        let priceTitle = UILabel()
        priceTitle.text = "금액"
        priceTitle.font = UIFont.systemFont(ofSize: 12)
        priceTitle.textColor = .gray

        let priceFormatter = NumberFormatter()
        priceFormatter.numberStyle = .decimal
        let priceString = priceFormatter.string(from: NSNumber(value: reservation.price)) ?? "\(reservation.price)"
        let priceLabel = UILabel()
        priceLabel.text = "\(priceString)원"
        priceLabel.font = UIFont.boldSystemFont(ofSize: 14)

        let roomStack = UIStackView(arrangedSubviews: [roomTitle, roomLabel])
        roomStack.axis = .vertical
        roomStack.spacing = 2

        let priceStack = UIStackView(arrangedSubviews: [priceTitle, priceLabel])
        priceStack.axis = .vertical
        priceStack.spacing = 2

        let midStack = UIStackView(arrangedSubviews: [roomStack, priceStack])
        midStack.axis = .horizontal
        midStack.distribution = .fillEqually
        midStack.spacing = 8

        // 체크인 / 체크아웃 날짜
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let checkInTitle = UILabel()
        checkInTitle.text = "체크인"
        checkInTitle.font = UIFont.systemFont(ofSize: 12)
        checkInTitle.textColor = .gray

        let checkInLabel = UILabel()
        checkInLabel.text = dateFormatter.string(from: reservation.startDate)
        checkInLabel.font = UIFont.boldSystemFont(ofSize: 14)

        let checkOutTitle = UILabel()
        checkOutTitle.text = "체크아웃"
        checkOutTitle.font = UIFont.systemFont(ofSize: 12)
        checkOutTitle.textColor = .gray

        let checkOutLabel = UILabel()
        checkOutLabel.text = dateFormatter.string(from: reservation.endDate)
        checkOutLabel.font = UIFont.boldSystemFont(ofSize: 14)

        let checkInStack = UIStackView(arrangedSubviews: [checkInTitle, checkInLabel])
        checkInStack.axis = .vertical
        checkInStack.spacing = 2

        let checkOutStack = UIStackView(arrangedSubviews: [checkOutTitle, checkOutLabel])
        checkOutStack.axis = .vertical
        checkOutStack.spacing = 2

        let dateStack = UIStackView(arrangedSubviews: [checkInStack, checkOutStack])
        dateStack.axis = .horizontal
        dateStack.distribution = .fillEqually
        dateStack.spacing = 8

        let separator = UIView()
        separator.backgroundColor = UIColor(white: 0.9, alpha: 1.0)
        separator.translatesAutoresizingMaskIntoConstraints = false
        separator.heightAnchor.constraint(equalToConstant: 1).isActive = true

        // 연락처
        let contactLabel = UILabel()
        contactLabel.text = "연락처: \(reservation.phone)"
        contactLabel.font = UIFont.systemFont(ofSize: 13)
        contactLabel.textColor = .darkGray

        let faceIdLabel = UILabel()
        faceIdLabel.text = reservation.useFaceId ? "얼굴인식 체크인 사용" : "얼굴인식 체크인 사용안함"
        faceIdLabel.font = UIFont.systemFont(ofSize: 13)
        faceIdLabel.textColor = reservation.useFaceId
            ? UIColor(red: 47/255, green: 175/255, blue: 83/255, alpha: 1)
            : .gray

        let contactStack = UIStackView(arrangedSubviews: [contactLabel, faceIdLabel])
        contactStack.axis = .horizontal
        contactStack.distribution = .equalSpacing
        contactStack.translatesAutoresizingMaskIntoConstraints = false

        let totalStack = UIStackView(arrangedSubviews: [topStack, midStack, dateStack])
        totalStack.axis = .vertical
        totalStack.spacing = 12
        totalStack.translatesAutoresizingMaskIntoConstraints = false
        totalStack.addArrangedSubview(separator)
        totalStack.addArrangedSubview(contactStack)

        // 예약 상태 라벨
        let statusLabel = UILabel()
        statusLabel.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        statusLabel.textAlignment = .center
        statusLabel.layer.cornerRadius = 10
        statusLabel.clipsToBounds = true
        statusLabel.widthAnchor.constraint(equalToConstant: 40).isActive = true
        statusLabel.heightAnchor.constraint(equalToConstant: 24).isActive = true

        // 실시간 checkIn 감지
        let db = Firestore.firestore()
        db.collection("reserves").document(reservation.id).addSnapshotListener { snapshot, error in
            guard let data = snapshot?.data() else { return }
            let checkIn = data["checkIn"] as? Bool ?? false
            DispatchQueue.main.async {
                self.updateReservationStatusLabel(statusLabel, reservation: reservation, checkIn: checkIn)
            }
        }

        // 예약 취소 버튼
        let cancelButton = UIButton(type: .system)
        cancelButton.setTitle("예약 취소", for: .normal)
        cancelButton.setTitleColor(.white, for: .normal)
        cancelButton.backgroundColor = .red
        cancelButton.layer.cornerRadius = 10
        cancelButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        cancelButton.addAction(UIAction { [weak self] _ in
            guard let self = self else { return }
            let alert = UIAlertController(title: "예약을 취소하시겠습니까?", message: "예약번호: \(reservation.reserveNumber)", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "취소", style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(title: "확인", style: .destructive, handler: { _ in
                self.cancelReservation(reservation)
            }))
            self.present(alert, animated: true, completion: nil)
        }, for: .touchUpInside)

        container.addSubview(totalStack)
        container.addSubview(cancelButton)
        container.addSubview(statusLabel)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            totalStack.topAnchor.constraint(equalTo: container.topAnchor, constant: 12),
            totalStack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
            totalStack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -12),

            cancelButton.topAnchor.constraint(equalTo: totalStack.bottomAnchor, constant: 12),
            cancelButton.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -12),
            cancelButton.widthAnchor.constraint(equalTo: container.widthAnchor, multiplier: 0.3),
            cancelButton.heightAnchor.constraint(equalToConstant: 36),
            cancelButton.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -12),

            statusLabel.centerYAnchor.constraint(equalTo: cancelButton.centerYAnchor),
            statusLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12)
        ])

        stackView.addArrangedSubview(container)
    }

    // 예약 상태 라벨 업데이트
    private func updateReservationStatusLabel(_ label: UILabel, reservation: Reservation, checkIn: Bool) {
        let now = Date()
        if now > reservation.endDate {
            label.text = "완료"
            label.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.1)
            label.textColor = UIColor.systemBlue
        } else if checkIn && now < reservation.endDate {
            label.text = "확정"
            label.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.1)
            label.textColor = UIColor.systemGreen
        } else {
            label.text = "대기"
            label.backgroundColor = UIColor.systemYellow.withAlphaComponent(0.2)
            label.textColor = UIColor.brown
        }
    }
    
    // UISearchBarDelegate
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        let keyword = searchText.lowercased()
        guard let title = dateSelectButton.title(for: .normal) else { return }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy년 MM월 dd일"
        guard let selected = formatter.date(from: title) else { return }
        let selectedDay = Calendar.current.startOfDay(for: selected)

        let dateFiltered = reservations.filter {
            let start = Calendar.current.startOfDay(for: $0.startDate)
            let end = Calendar.current.startOfDay(for: $0.endDate)
            return selectedDay >= start && selectedDay <= end
        }

        filteredReservations = keyword.isEmpty
            ? dateFiltered
            : dateFiltered.filter {
                $0.userName.lowercased().contains(keyword) ||
                String($0.reserveNumber).contains(keyword)
            }

        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        filteredReservations.forEach { addReservationView($0) }
    }
    
    @objc private func presentDatePicker() {
        let alert = UIAlertController(title: "날짜 선택", message: "\n\n\n\n\n\n\n\n", preferredStyle: .actionSheet)
        let picker = UIDatePicker()
        picker.datePickerMode = .date
        picker.locale = Locale(identifier: "ko_KR")
        picker.preferredDatePickerStyle = .wheels
        picker.frame = CGRect(x: 0, y: 30, width: alert.view.bounds.width - 20, height: 200)
        alert.view.addSubview(picker)

        alert.addAction(UIAlertAction(title: "취소", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "선택", style: .default, handler: { _ in
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy년 MM월 dd일"
            let selectedDate = formatter.string(from: picker.date)
            self.dateSelectButton.setTitle(selectedDate, for: .normal)
            self.reloadFilteredReservations()
        }))

        self.present(alert, animated: true, completion: nil)
    }
}

private extension ManageReservationViewController {
    func applyDefaultDateFilter() {
        let today = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy년 MM월 dd일"
        self.dateSelectButton.setTitle(formatter.string(from: today), for: .normal)
    }

    func reloadFilteredReservations() {
        guard let title = dateSelectButton.title(for: .normal) else { return }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy년 MM월 dd일"
        guard let selected = formatter.date(from: title) else { return }
        let selectedDay = Calendar.current.startOfDay(for: selected)

        self.filteredReservations = self.reservations.filter {
            let start = Calendar.current.startOfDay(for: $0.startDate)
            let end = Calendar.current.startOfDay(for: $0.endDate)
            return selectedDay >= start && selectedDay <= end
        }.sorted {
            let selectedCheckInEqual = Calendar.current.isDate($0.startDate, inSameDayAs: selectedDay)
            let selectedCheckOutEqual = Calendar.current.isDate($0.endDate, inSameDayAs: selectedDay)

            let otherCheckInEqual = Calendar.current.isDate($1.startDate, inSameDayAs: selectedDay)
            let otherCheckOutEqual = Calendar.current.isDate($1.endDate, inSameDayAs: selectedDay)

            if selectedCheckInEqual != otherCheckInEqual {
                return selectedCheckInEqual
            } else if selectedCheckOutEqual != otherCheckOutEqual {
                return selectedCheckOutEqual
            } else {
                return $0.startDate < $1.startDate
            }
        }

        self.stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        self.filteredReservations.forEach { self.addReservationView($0) }
    }

    fileprivate func cancelReservation(_ reservation: Reservation) {
        let db = Firestore.firestore()
        db.collection("reserves").document(reservation.id).delete { [weak self] error in
            if let error = error {
                print("예약 삭제 실패: \(error)")
            } else {
                print("예약 삭제 성공")
                self?.reservations.removeAll { $0.id == reservation.id }
                self?.reloadFilteredReservations()
            }
        }
    }

    internal override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadFilteredReservations()
    }
}
