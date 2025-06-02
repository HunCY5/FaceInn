//
//  ReserveInfoViewController.swift
//  FaceInn
//
//  Created by CHOI on 6/3/25.
//


import UIKit
import FirebaseFirestore

class ReserveInfoViewController: UIViewController {
    // 전달받는 데이터
    var reserveID: String = ""
    var userID: String = ""
    var userData: [String: Any] = [:]
    var isCheckIn: Bool = true
    var reserveData: [String: Any] = [:]

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 18/255, green: 24/255, blue: 34/255, alpha: 1)
        setupCardUI()
    }

    private func setupCardUI() {
        let icon = UIImageView(image: UIImage(systemName: "person.crop.circle.fill")?.withRenderingMode(.alwaysTemplate))
        icon.tintColor = UIColor.systemGreen
        icon.contentMode = .scaleAspectFit
        icon.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(icon)
        NSLayoutConstraint.activate([
            icon.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            icon.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            icon.widthAnchor.constraint(equalToConstant: 54),
            icon.heightAnchor.constraint(equalToConstant: 54)
        ])

        let titleLabel = UILabel()
        titleLabel.text = "인식 완료"
        titleLabel.font = .systemFont(ofSize: 22, weight: .bold)
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: icon.bottomAnchor, constant: 10),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])

        let subtitleLabel = UILabel()
        subtitleLabel.text = "예약 정보를 확인해주세요"
        subtitleLabel.font = .systemFont(ofSize: 14)
        subtitleLabel.textColor = UIColor(white: 1, alpha: 0.7)
        subtitleLabel.textAlignment = .center
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(subtitleLabel)
        NSLayoutConstraint.activate([
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 2),
            subtitleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])

        let card = UIView()
        card.backgroundColor = UIColor(white: 1, alpha: 0.06)
        card.layer.cornerRadius = 14
        card.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(card)
        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 24),
            card.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            card.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])

        let nameLabel = UILabel()
        let userName = userData["name"] as? String ?? "-"
        nameLabel.text = userName
        nameLabel.font = .boldSystemFont(ofSize: 20)
        nameLabel.textColor = UIColor.systemGreen
        nameLabel.textAlignment = .center

        let nameSubLabel = UILabel()
        nameSubLabel.text = "님의 예약 정보"
        nameSubLabel.font = .systemFont(ofSize: 13)
        nameSubLabel.textColor = UIColor(white: 1, alpha: 0.6)
        nameSubLabel.textAlignment = .center

        let roomName = reserveData["roomName"] as? String ?? "-"
        let roomType = reserveData["roomType"] as? String ?? ""
        let roomLabel = UILabel()
        roomLabel.text = roomName + (roomType.isEmpty ? "" : " (\(roomType))")
        roomLabel.font = .boldSystemFont(ofSize: 24)
        roomLabel.textColor = UIColor.white
        roomLabel.textAlignment = .center
        roomLabel.backgroundColor = UIColor(white: 1, alpha: 0.10)
        roomLabel.layer.cornerRadius = 8
        roomLabel.clipsToBounds = true
        roomLabel.heightAnchor.constraint(equalToConstant: 54).isActive = true

        // 날짜 포맷
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "ko_KR")
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let startDate = (reserveData["startDate"] as? Timestamp)?.dateValue()
        let endDate = (reserveData["endDate"] as? Timestamp)?.dateValue()
        let startStr = startDate != nil ? dateFormatter.string(from: startDate!) : "-"
        let endStr = endDate != nil ? dateFormatter.string(from: endDate!) : "-"

        // 숙박기간 포맷
        let nights = numberOfNights(start: startDate, end: endDate)
        let nightsStr = nights > 0 ? "\(nights)박 \(nights+1)일" : "-"

        // 인원수 포맷
        let guestCount = reserveData["guestCount"] as? Int ?? 0
        let guestCountStr = guestCount > 0 ? "\(guestCount)명" : "-"

        // 전화번호 포맷
        let phone = formatPhone(userData["phone"] as? String ?? "-")

        // 카드 내 정보 stackView
        let infoRows: [InfoRow] = [
            InfoRow(iconName: "calendar", label: "체크인", value: startStr),
            InfoRow(iconName: "calendar", label: "체크아웃", value: endStr),
            InfoRow(iconName: "calendar", label: "숙박 기간", value: nightsStr),
            InfoRow(iconName: "person.2", label: "인원수", value: guestCountStr),
            InfoRow(iconName: "phone", label: "연락처", value: phone)
        ]
        let infoStack = UIStackView(arrangedSubviews: infoRows)
        infoStack.axis = .vertical
        infoStack.spacing = 8
        infoStack.translatesAutoresizingMaskIntoConstraints = false

        let cardStack = UIStackView(arrangedSubviews: [nameLabel, nameSubLabel, roomLabel, infoStack])
        cardStack.axis = .vertical
        cardStack.spacing = 16
        cardStack.translatesAutoresizingMaskIntoConstraints = false

        card.addSubview(cardStack)
        NSLayoutConstraint.activate([
            cardStack.topAnchor.constraint(equalTo: card.topAnchor, constant: 20),
            cardStack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 20),
            cardStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -20),
            cardStack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -20)
        ])

        let button = UIButton(type: .system)
        button.setTitle(isCheckIn ? "체크인 하기" : "체크아웃 하기", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = isCheckIn ? UIColor.systemGreen : UIColor.systemBlue
        button.layer.cornerRadius = 12
        button.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(button)
        NSLayoutConstraint.activate([
            button.topAnchor.constraint(equalTo: card.bottomAnchor, constant: 36),
            button.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            button.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            button.heightAnchor.constraint(equalToConstant: 54)
        ])
        button.addTarget(self, action: #selector(handleActionButton), for: .touchUpInside)
    }

    @objc private func handleActionButton() {
        // 이미 체크인/체크아웃 상태면 처리 중단 및 알림
        if isCheckIn, let checked = reserveData["checkIn"] as? Bool, checked == true {
            showCompletionAndGoBack(message: "이미 체크인된 예약입니다.")
            return
        }
        if !isCheckIn, let checked = reserveData["checkOut"] as? Bool, checked == true {
            showCompletionAndGoBack(message: "이미 체크아웃된 예약입니다.")
            return
        }
        let db = Firestore.firestore()
        let now = Timestamp(date: Date())
        let ref = db.collection("reserves").document(reserveID)
        if isCheckIn {
            // 체크인 처리
            ref.updateData([
                "checkIn": true,
                "checkInTimeStamp": now
            ]) { [weak self] error in
                if let error = error {
                    self?.showAlert(title: "오류", message: "체크인 처리 실패: \(error.localizedDescription)")
                } else {
                    self?.reserveData["checkIn"] = true
                    self?.reserveData["checkInTimeStamp"] = now
                    self?.showCompletionAndGoBack(message: "체크인이 완료되었습니다.")
                }
            }
        } else {
            // 체크아웃 처리
            ref.updateData([
                "checkIn": false,
                "checkOut": true,
                "checkOutTimeStamp": now
            ]) { [weak self] error in
                if let error = error {
                    self?.showAlert(title: "오류", message: "체크아웃 처리 실패: \(error.localizedDescription)")
                } else {
                    self?.reserveData["checkIn"] = false
                    self?.reserveData["checkOut"] = true
                    self?.reserveData["checkOutTimeStamp"] = now
                    self?.showCompletionAndGoBack(message: "체크아웃이 완료되었습니다.")
                }
            }
        }
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default, handler: nil))
        present(alert, animated: true)
    }

    private func numberOfNights(start: Date?, end: Date?) -> Int {
        guard let start = start, let end = end else { return 0 }
        let cal = Calendar.current
        let s = cal.startOfDay(for: start)
        let e = cal.startOfDay(for: end)
        let comps = cal.dateComponents([.day], from: s, to: e)
        return comps.day ?? 0
    }

    private func formatPhone(_ phone: String) -> String {
        // 01012341234 -> 010-1234-1234
        let numbers = phone.filter { $0.isNumber }
        if numbers.count == 11 {
            let s = numbers
            let first = s.prefix(3)
            let mid = s.dropFirst(3).prefix(4)
            let last = s.suffix(4)
            return "\(first)-\(mid)-\(last)"
        }
        return phone
    }
    // 체크인/체크아웃 완료 후 안내 및 이전 화면 이동
    private func showCompletionAndGoBack(message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default) { [weak self] _ in
            self?.goBackToGuestCamera()
        })
        present(alert, animated: true) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 10) { [weak self] in
                if self?.presentedViewController == alert {
                    self?.dismiss(animated: true) {
                        self?.goBackToGuestCamera()
                    }
                }
            }
        }
    }

    private func goBackToGuestCamera() {
        if let nav = navigationController {
            for vc in nav.viewControllers {
                if vc is GuestCameraViewController {
                    nav.popToViewController(vc, animated: true)
                    return
                }
            }
            nav.popToRootViewController(animated: true)
        } else {
            dismiss(animated: true)
        }
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if self.isMovingFromParent {
            goBackToGuestCamera()
        }
    }
}

// 카드 내 정보 한 줄(아이콘+라벨+값) 뷰 컴포넌트
class InfoRow: UIView {
    init(iconName: String, label: String, value: String) {
        super.init(frame: .zero)
        let iconView = UIImageView(image: UIImage(systemName: iconName))
        iconView.tintColor = UIColor(white: 1, alpha: 0.85)
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.widthAnchor.constraint(equalToConstant: 22).isActive = true
        iconView.heightAnchor.constraint(equalToConstant: 22).isActive = true

        let labelLabel = UILabel()
        labelLabel.text = label
        labelLabel.font = .systemFont(ofSize: 15, weight: .medium)
        labelLabel.textColor = UIColor(white: 1, alpha: 0.7)
        labelLabel.translatesAutoresizingMaskIntoConstraints = false

        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.font = .systemFont(ofSize: 16, weight: .bold)
        valueLabel.textColor = .white
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        valueLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)

        let stack = UIStackView(arrangedSubviews: [iconView, labelLabel, valueLabel])
        stack.axis = .horizontal
        stack.spacing = 10
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false

        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }
    required init?(coder: NSCoder) { fatalError() }
}
