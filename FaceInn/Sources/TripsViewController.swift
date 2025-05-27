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
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
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
        let nights = startDate != nil && endDate != nil ? Calendar.current.dateComponents([.day], from: startDate!, to: endDate!).day ?? 1 : 1
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

        let useFaceId = reservation["useFaceId"] as? Bool ?? false
        cell.faceIdStatusLabel.text = useFaceId ? "얼굴인식 체크인 사용" : "얼굴인식 체크인 사용 안함"

        cell.showCancelButton(selectedTab == 0)
        cell.faceCheckinButton.isEnabled = !useFaceId
        cell.faceCheckinButton.backgroundColor = useFaceId
            ? .lightGray
            : UIColor(red: 47/255, green: 175/255, blue: 83/255, alpha: 1)
        cell.disableFaceIdButton.isEnabled = useFaceId
        cell.disableFaceIdButton.backgroundColor = useFaceId
            ? UIColor(red: 47/255, green: 175/255, blue: 83/255, alpha: 1)
            : .lightGray
        cell.documentId = reservation["documentId"] as? String

        // Hide buttons if selectedTab == 1 (이용후)
        if selectedTab == 1 {
            cell.faceCheckinButton.isHidden = true
            cell.disableFaceIdButton.isHidden = true
        } else {
            cell.faceCheckinButton.isHidden = false
            cell.disableFaceIdButton.isHidden = false
        }

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
    let faceIdStatusLabel = UILabel()
    let checkInLabel = UILabel()
    let checkOutLabel = UILabel()
    let checkInDateLabel = UILabel()
    let checkOutDateLabel = UILabel()
    let cancelButton = UIButton(type: .system)
    let faceCheckinButton = UIButton(type: .system)
    let disableFaceIdButton = UIButton(type: .system)

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

        faceIdStatusLabel.font = UIFont.systemFont(ofSize: 12)
        faceIdStatusLabel.textColor = .gray
        faceIdStatusLabel.translatesAutoresizingMaskIntoConstraints = false

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
        cancelButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 12)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.heightAnchor.constraint(equalToConstant: 30).isActive = true
        cancelButton.addTarget(self, action: #selector(handleCancelTapped), for: .touchUpInside)

        // 얼굴인식 체크인 버튼 설정
        faceCheckinButton.setTitle("얼굴인식 체크인", for: .normal)
        faceCheckinButton.setTitleColor(.white, for: .normal)
        faceCheckinButton.backgroundColor = UIColor(red: 47/255, green: 175/255, blue: 83/255, alpha: 1)
        faceCheckinButton.layer.cornerRadius = 8
        faceCheckinButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 12)
        faceCheckinButton.translatesAutoresizingMaskIntoConstraints = false
        faceCheckinButton.heightAnchor.constraint(equalToConstant: 30).isActive = true
        faceCheckinButton.addTarget(self, action: #selector(handleFaceCheckinTapped), for: .touchUpInside)

        // 얼굴인식 체크인 사용안함 버튼 설정
        disableFaceIdButton.setTitle("얼굴인식 해제", for: .normal)
        disableFaceIdButton.setTitleColor(.white, for: .normal)
        disableFaceIdButton.backgroundColor = .darkGray
        disableFaceIdButton.layer.cornerRadius = 8
        disableFaceIdButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 12)
        disableFaceIdButton.translatesAutoresizingMaskIntoConstraints = false
        disableFaceIdButton.heightAnchor.constraint(equalToConstant: 30).isActive = true
        disableFaceIdButton.addTarget(self, action: #selector(handleDisableFaceIdTapped), for: .touchUpInside)

        // 버튼 터치 애니메이션 효과 추가 (각 버튼에 명시적으로 이벤트 추가)
        faceCheckinButton.addTarget(self, action: #selector(buttonTouchDown(_:)), for: .touchDown)
        faceCheckinButton.addTarget(self, action: #selector(buttonTouchUp(_:)), for: [.touchUpInside, .touchUpOutside, .touchCancel])

        disableFaceIdButton.addTarget(self, action: #selector(buttonTouchDown(_:)), for: .touchDown)
        disableFaceIdButton.addTarget(self, action: #selector(buttonTouchUp(_:)), for: [.touchUpInside, .touchUpOutside, .touchCancel])

        cancelButton.addTarget(self, action: #selector(buttonTouchDown(_:)), for: .touchDown)
        cancelButton.addTarget(self, action: #selector(buttonTouchUp(_:)), for: [.touchUpInside, .touchUpOutside, .touchCancel])

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

        let infoStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel, faceIdStatusLabel])
        infoStack.axis = .vertical
        infoStack.spacing = 2

        let buttonStack = UIStackView(arrangedSubviews: [faceCheckinButton, disableFaceIdButton, cancelButton])
        buttonStack.axis = .horizontal
        buttonStack.spacing = 8
        buttonStack.distribution = .fillEqually

        let contentStack = UIStackView(arrangedSubviews: [infoStack, dateStack, buttonStack])
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

    @objc private func handleFaceCheckinTapped() {
        guard let user = Auth.auth().currentUser,
              let docId = documentId,
              let viewController = self.findViewController() else { return }

        let db = Firestore.firestore()
        db.collection("users").document(user.uid).getDocument { snapshot, error in
            let data = snapshot?.data()
            let hasVector = data?["front_vector"] != nil || data?["left_vector"] != nil || data?["right_vector"] != nil

            if !hasVector {
                let alert = UIAlertController(title: "얼굴 정보 없음", message: "얼굴을 등록해주세요.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "취소", style: .cancel, handler: nil))
                alert.addAction(UIAlertAction(title: "확인", style: .default) { _ in
                    let vc = FaceCaptureViewController()
                    vc.documentId = docId
                    viewController.navigationController?.pushViewController(vc, animated: true)
                })
                viewController.present(alert, animated: true)
                NotificationCenter.default.addObserver(self, selector: #selector(self.updateUseFaceIdAfterCapture), name: NSNotification.Name("FaceIdRegisteredWithDocId"), object: nil)
                return
            } else {
                let confirmAlert = UIAlertController(title: "얼굴인식 체크인", message: "얼굴인식을 사용해서 체크인 하시겠습니까?", preferredStyle: .alert)
                confirmAlert.addAction(UIAlertAction(title: "취소", style: .cancel))
                confirmAlert.addAction(UIAlertAction(title: "확인", style: .default) { _ in
                    db.collection("reserves").document(docId).updateData(["useFaceId": true]) { error in
                        if let error = error {
                            print("업데이트 실패: \(error)")
                        } else {
                            print("useFaceId가 true로 설정됨")
                            NotificationCenter.default.post(name: NSNotification.Name("ReservationCancelled"), object: nil)
                        }
                    }
                })
                viewController.present(confirmAlert, animated: true)
            }
        }
    }

    @objc private func updateUseFaceIdAfterCapture(_ notification: Notification) {
        guard let docId = notification.userInfo?["documentId"] as? String,
              let myDocId = self.documentId,
              docId == myDocId else { return }

        Firestore.firestore().collection("reserves").document(docId).updateData(["useFaceId": true]) { error in
            if let error = error {
                print("useFaceId 업데이트 실패: \(error)")
            } else {
                print("useFaceId가 true로 설정됨")
                NotificationCenter.default.post(name: NSNotification.Name("ReservationCancelled"), object: nil)
            }
        }
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name("FaceIdRegisteredWithDocId"), object: nil)
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

    @objc private func handleDisableFaceIdTapped() {
        guard let docId = documentId,
              let viewController = self.findViewController() else { return }

        let confirmAlert = UIAlertController(title: "얼굴인식 체크인 해제", message: "얼굴인식 체크인을 해제 하시겠습니까?", preferredStyle: .alert)
        confirmAlert.addAction(UIAlertAction(title: "취소", style: .cancel))
        confirmAlert.addAction(UIAlertAction(title: "확인", style: .destructive) { _ in
            Firestore.firestore().collection("reserves").document(docId).updateData(["useFaceId": false]) { error in
                if let error = error {
                    print("얼굴인식 사용안함 설정 실패: \(error)")
                } else {
                    print("useFaceId가 false로 설정됨")
                    NotificationCenter.default.post(name: NSNotification.Name("ReservationCancelled"), object: nil)
                }
            }
        })
        viewController.present(confirmAlert, animated: true)
    }

    @objc private func buttonTouchDown(_ sender: UIButton) {
        UIView.animate(withDuration: 0.15,
                       delay: 0,
                       usingSpringWithDamping: 0.4,
                       initialSpringVelocity: 6,
                       options: .curveEaseInOut,
                       animations: {
            sender.transform = CGAffineTransform(scaleX: 0.93, y: 0.93)
        }, completion: nil)
    }

    @objc private func buttonTouchUp(_ sender: UIButton) {
        UIView.animate(withDuration: 0.25,
                       delay: 0,
                       usingSpringWithDamping: 0.5,
                       initialSpringVelocity: 2,
                       options: .curveEaseOut,
                       animations: {
            sender.transform = .identity
        }, completion: nil)
    }
}
