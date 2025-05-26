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

    private func setupTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(ReservationCell.self, forCellReuseIdentifier: "Cell")
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: segmentControl.bottomAnchor, constant: 8),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func fetchReservations() {
        guard let user = Auth.auth().currentUser else { return }
        let db = Firestore.firestore()
        db.collection("reserves").whereField("userId", isEqualTo: user.uid).getDocuments { snapshot, error in
            guard let documents = snapshot?.documents, error == nil else {
                print("예약 정보를 불러오지 못했습니다:", error?.localizedDescription ?? "알 수 없음")
                return
            }
            let now = Date()
            self.upcomingReservations = []
            self.pastReservations = []
            for doc in documents {
                var data = doc.data()
                data["documentId"] = doc.documentID
                if let end = (data["endDate"] as? Timestamp)?.dateValue(), end > now {
                    self.upcomingReservations.append(data)
                } else {
                    self.pastReservations.append(data)
                }
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
        cell.subtitleLabel.text = "\(reservation["roomName"] as? String ?? "객실명 없음") • \(reservation["numberOfNights"] as? Int ?? 1)박"

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

        cell.showCancelButton(selectedTab == 0)
        cell.documentId = reservation["documentId"] as? String

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

// MARK: - ReservationCell
class ReservationCell: UITableViewCell {
    let thumbnailImageView = UIImageView()
    let titleLabel = UILabel()
    let subtitleLabel = UILabel()
    let checkInLabel = UILabel()
    let checkOutLabel = UILabel()
    let checkInDateLabel = UILabel()
    let checkOutDateLabel = UILabel()
    let cancelButton = UIButton(type: .system)

    var documentId: String?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        thumbnailImageView.translatesAutoresizingMaskIntoConstraints = false
        thumbnailImageView.contentMode = .scaleAspectFill
        thumbnailImageView.clipsToBounds = true
        thumbnailImageView.layer.cornerRadius = 8

        titleLabel.font = UIFont.boldSystemFont(ofSize: 16)
        subtitleLabel.font = UIFont.systemFont(ofSize: 14)
        subtitleLabel.textColor = .darkGray
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false

        // 체크인/체크아웃 레이블
        checkInLabel.text = "체크인"
        checkInLabel.font = UIFont.systemFont(ofSize: 12)
        checkInLabel.textColor = .gray
        checkInDateLabel.font = UIFont.boldSystemFont(ofSize: 16)

        checkOutLabel.text = "체크아웃"
        checkOutLabel.font = UIFont.systemFont(ofSize: 12)
        checkOutLabel.textColor = .gray
        checkOutDateLabel.font = UIFont.boldSystemFont(ofSize: 16)

        // 예약 취소하기 버튼 설정
        cancelButton.setTitle("예약 취소하기", for: .normal)
        cancelButton.setTitleColor(.white, for: .normal)
        cancelButton.backgroundColor = .systemRed
        cancelButton.layer.cornerRadius = 8
        cancelButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.heightAnchor.constraint(equalToConstant: 30).isActive = true
        cancelButton.addTarget(self, action: #selector(handleCancelTapped), for: .touchUpInside)

        // 수평 스택
        let dateStack = UIStackView()
        let checkInStack = UIStackView(arrangedSubviews: [checkInLabel, checkInDateLabel])
        let checkOutStack = UIStackView(arrangedSubviews: [checkOutLabel, checkOutDateLabel])
        checkInStack.axis = .vertical
        checkOutStack.axis = .vertical
        dateStack.axis = .horizontal
        dateStack.distribution = .fillEqually
        dateStack.spacing = 8
        dateStack.addArrangedSubview(checkInStack)
        dateStack.addArrangedSubview(checkOutStack)

        let infoStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        infoStack.axis = .vertical
        infoStack.spacing = 2

        let contentStack = UIStackView(arrangedSubviews: [infoStack, dateStack, cancelButton])
        contentStack.axis = .vertical
        contentStack.spacing = 12
        contentStack.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(thumbnailImageView)
        contentView.addSubview(contentStack)

        NSLayoutConstraint.activate([
            thumbnailImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            thumbnailImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            thumbnailImageView.widthAnchor.constraint(equalToConstant: 80),
            thumbnailImageView.heightAnchor.constraint(equalToConstant: 80),

            contentStack.leadingAnchor.constraint(equalTo: thumbnailImageView.trailingAnchor, constant: 12),
            contentStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            contentStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            contentStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    func showCancelButton(_ visible: Bool) {
        cancelButton.isHidden = !visible
    }

    @objc private func handleCancelTapped() {
        guard let viewController = self.findViewController() else { return }

        let alert = UIAlertController(title: "예약 취소", message: "예약을 취소하시겠습니까?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "취소", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "확인", style: .destructive, handler: { _ in
            self.cancelReservation()
        }))
        viewController.present(alert, animated: true)
    }

    private func cancelReservation() {
        guard let docId = documentId else { return }
        Firestore.firestore().collection("reserves").document(docId).delete { error in
            if let error = error {
                print("예약 삭제 실패: \(error.localizedDescription)")
            } else {
                print("예약 취소됨")
                NotificationCenter.default.post(name: NSNotification.Name("ReservationCancelled"), object: nil)
            }
        }
    }

    private func findViewController() -> UIViewController? {
        var responder: UIResponder? = self
        while let r = responder {
            if let vc = r as? UIViewController {
                return vc
            }
            responder = r.next
        }
        return nil
    }
}
