//
//  CheckInViewController.swift
//  FaceInn
//
//  Created by CHOI on 5/28/25.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

final class CheckInViewController: UIViewController {

    // MARK: - 통계 데이터 (Firestore 실시간)
    private var statItems: [StatItem] = []
    // 통계 뷰와 valueLabel을 함께 저장하여 값만 갱신할 수 있도록
    private var statViews: [(container: UIView, valueLabel: UILabel)] = []

    private let dummyRecents: [RecentRecognition] = [
        RecentRecognition(guestName: "김철수", roomNumber: "객실 101", mode: .checkin, time: "14:23"),
        RecentRecognition(guestName: "이영희", roomNumber: "객실 203", mode: .checkout, time: "11:45"),
        RecentRecognition(guestName: "박민수", roomNumber: "객실 305", mode: .checkin, time: "16:12"),
        // 테스트용 더미 데이터를 더 추가하면 테이블뷰가 스크롤됩니다.
        RecentRecognition(guestName: "테스트1", roomNumber: "객실 401", mode: .checkout, time: "10:00"),
        RecentRecognition(guestName: "테스트2", roomNumber: "객실 402", mode: .checkin, time: "10:05"),
        RecentRecognition(guestName: "테스트3", roomNumber: "객실 403", mode: .checkout, time: "10:10")
    ]

    // MARK: - View 프로퍼티

    // 1) Guest Check-In Card
    private let guestCardView = UIView()
    private let guestTitleLabel = UILabel()
    private let openGuestButton = UIButton(type: .system)

    // 2) Stat Grid: 2x2 그리드
    private let statsContainer = UIView()

    // 3) Recent Recognition Section: 테이블뷰만 스크롤
    private let recentHeaderLabel = UILabel()
    private let recentTableView = UITableView(frame: .zero, style: .plain)

    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        setupNavigationBar()
        configureGuestCard()
        configureStatsGrid()
        configureRecentSection()
        // Firestore에서 통계 실시간 집계
        fetchStats()
    }

    // MARK: - 네비게이션 바 설정

    private func setupNavigationBar() {
        navigationItem.title = "체크인 관리"
        navigationController?.navigationBar.prefersLargeTitles = false
    }

    // MARK: - 1) Guest Check-In Card 구성

    private func configureGuestCard() {
        guestCardView.translatesAutoresizingMaskIntoConstraints = false
        guestCardView.backgroundColor = .secondarySystemBackground
        guestCardView.layer.cornerRadius = 12

        // 타이틀 레이블
        guestTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        guestTitleLabel.text = "게스트 체크인"
        guestTitleLabel.font = UIFont.systemFont(ofSize: 20, weight: .semibold)

        // 서브타이틀 레이블
        let guestSubtitleLabel = UILabel()
        guestSubtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        guestSubtitleLabel.text = "게스트가 얼굴 인식으로 체크인할 수 있는 화면입니다"
        guestSubtitleLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        guestSubtitleLabel.textColor = .secondaryLabel

        // 버튼
        openGuestButton.translatesAutoresizingMaskIntoConstraints = false
        openGuestButton.setTitle("📷  게스트 체크인 화면 열기", for: .normal)
        openGuestButton.setTitleColor(.white, for: .normal)
        openGuestButton.backgroundColor = UIColor(red: 46/255, green: 173/255, blue: 83/255, alpha: 1) // #2FAF53
        openGuestButton.layer.cornerRadius = 8
        openGuestButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        openGuestButton.contentEdgeInsets = UIEdgeInsets(top: 12, left: 0, bottom: 12, right: 0)
        openGuestButton.addTarget(self, action: #selector(didTapOpenGuest), for: .touchUpInside)

        view.addSubview(guestCardView)
        guestCardView.addSubview(guestTitleLabel)
        guestCardView.addSubview(guestSubtitleLabel)
        guestCardView.addSubview(openGuestButton)

        NSLayoutConstraint.activate([
            // guestCardView: 상단 safeArea 바로 아래, 좌/우 16pt 여백
            guestCardView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            guestCardView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            guestCardView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            guestCardView.bottomAnchor.constraint(equalTo: openGuestButton.bottomAnchor, constant: 16),

            // guestTitleLabel: 카드 내부 상단 16pt
            guestTitleLabel.topAnchor.constraint(equalTo: guestCardView.topAnchor, constant: 16),
            guestTitleLabel.leadingAnchor.constraint(equalTo: guestCardView.leadingAnchor, constant: 16),
            guestTitleLabel.trailingAnchor.constraint(equalTo: guestCardView.trailingAnchor, constant: -16),

            // guestSubtitleLabel: 타이틀 아래 4pt
            guestSubtitleLabel.topAnchor.constraint(equalTo: guestTitleLabel.bottomAnchor, constant: 4),
            guestSubtitleLabel.leadingAnchor.constraint(equalTo: guestTitleLabel.leadingAnchor),
            guestSubtitleLabel.trailingAnchor.constraint(equalTo: guestTitleLabel.trailingAnchor),

            // openGuestButton: subtitle 아래 16pt, 높이 44, 그리고 카드 바닥으로부터 16pt 여백
            openGuestButton.topAnchor.constraint(equalTo: guestSubtitleLabel.bottomAnchor, constant: 16),
            openGuestButton.leadingAnchor.constraint(equalTo: guestCardView.leadingAnchor, constant: 16),
            openGuestButton.trailingAnchor.constraint(equalTo: guestCardView.trailingAnchor, constant: -16),
            openGuestButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    @objc private func didTapOpenGuest() {
        let guestCameraVC = GuestCameraViewController()
        let nav = UINavigationController(rootViewController: guestCameraVC)

        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let delegate = scene.delegate as? SceneDelegate,
           let window = delegate.window {
            window.rootViewController = nav
            window.makeKeyAndVisible()
        }
    }

    // MARK: - 2) Stats Grid 구성 (2x2)

    private func configureStatsGrid() {
        statsContainer.translatesAutoresizingMaskIntoConstraints = false

        let gridStack = UIStackView()
        gridStack.translatesAutoresizingMaskIntoConstraints = false
        gridStack.axis = .vertical
        gridStack.spacing = 12

        let topRow = UIStackView()
        topRow.axis = .horizontal
        topRow.distribution = .fillEqually
        topRow.spacing = 12

        let bottomRow = UIStackView()
        bottomRow.axis = .horizontal
        bottomRow.distribution = .fillEqually
        bottomRow.spacing = 12

        // 기존 statViews 제거
        statViews.removeAll()
        // statItems가 비어있으면 placeholder로 4개 0을 보여줌
        let statsToShow: [StatItem]
        if statItems.isEmpty {
            statsToShow = [
                StatItem(title: "오늘 체크인", value: "0", iconName: "checkmark.circle.fill", iconTintColor: .systemGreen),
                StatItem(title: "오늘 체크아웃", value: "0", iconName: "checkmark.circle.fill", iconTintColor: .systemBlue),
                StatItem(title: "체크인 대기", value: "0", iconName: "clock.fill", iconTintColor: .systemOrange),
                StatItem(title: "체크아웃 대기", value: "0", iconName: "clock.fill", iconTintColor: .systemPurple)
            ]
        } else {
            statsToShow = statItems
        }
        for (index, stat) in statsToShow.enumerated() {
            let (statView, valueLabel) = createSingleStatView(item: stat)
            statViews.append((statView, valueLabel))
            if index < 2 {
                topRow.addArrangedSubview(statView)
            } else {
                bottomRow.addArrangedSubview(statView)
            }
        }

        gridStack.addArrangedSubview(topRow)
        gridStack.addArrangedSubview(bottomRow)
        statsContainer.addSubview(gridStack)
        view.addSubview(statsContainer)

        NSLayoutConstraint.activate([
            // statsContainer: guestCardView 바로 아래 16pt, 좌/우 16pt
            statsContainer.topAnchor.constraint(equalTo: guestCardView.bottomAnchor, constant: 16),
            statsContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            statsContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            // 각 행 높이 60pt
            topRow.heightAnchor.constraint(equalToConstant: 60),
            bottomRow.heightAnchor.constraint(equalToConstant: 60),

            // gridStack이 statsContainer 전체를 채우도록
            gridStack.topAnchor.constraint(equalTo: statsContainer.topAnchor),
            gridStack.leadingAnchor.constraint(equalTo: statsContainer.leadingAnchor),
            gridStack.trailingAnchor.constraint(equalTo: statsContainer.trailingAnchor),
            gridStack.bottomAnchor.constraint(equalTo: statsContainer.bottomAnchor)
        ])
    }

    // UILabel 반환형 추가, (UIView, UILabel) 튜플 반환
    private func createSingleStatView(item: StatItem) -> (UIView, UILabel) {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.backgroundColor = .secondarySystemBackground
        container.layer.cornerRadius = 10

        let icon = UIImageView(image: UIImage(systemName: item.iconName))
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.tintColor = item.iconTintColor

        let valueLabel = UILabel()
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        valueLabel.text = item.value
        valueLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)

        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = item.title
        titleLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        titleLabel.textColor = .secondaryLabel

        let textStack = UIStackView(arrangedSubviews: [titleLabel, valueLabel])
        textStack.translatesAutoresizingMaskIntoConstraints = false
        textStack.axis = .vertical
        textStack.spacing = 4

        container.addSubview(icon)
        container.addSubview(textStack)

        NSLayoutConstraint.activate([
            icon.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            icon.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
            icon.widthAnchor.constraint(equalToConstant: 28),
            icon.heightAnchor.constraint(equalToConstant: 28),

            textStack.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            textStack.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 8),
            textStack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -12)
        ])
        // valueLabel을 반환하여 나중에 값만 갱신 가능
        return (container, valueLabel)
    }

    // Firestore에서 오늘 체크인, 체크인 대기, 체크아웃, 체크아웃 대기 실시간 집계
    private func fetchStats() {
        guard let hostId = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        let startOfTomorrow = calendar.date(byAdding: .day, value: 1, to: startOfToday)!

        // 오늘 체크인/체크인 대기
        db.collection("reserves")
            .whereField("hostId", isEqualTo: hostId)
            .whereField("startDate", isGreaterThanOrEqualTo: Timestamp(date: startOfToday))
            .whereField("startDate", isLessThan: Timestamp(date: startOfTomorrow))
            .getDocuments { snapshot, error in
                guard let docs = snapshot?.documents else { return }

                let checkInCount = docs.filter { ($0.data()["checkIn"] as? Bool) == true }.count
                let checkInWaitCount = docs.filter { ($0.data()["checkIn"] as? Bool) != true }.count

                // 오늘 체크아웃/체크아웃 대기
                db.collection("reserves")
                    .whereField("hostId", isEqualTo: hostId)
                    .whereField("endDate", isGreaterThanOrEqualTo: Timestamp(date: startOfToday))
                    .whereField("endDate", isLessThan: Timestamp(date: startOfTomorrow))
                    .getDocuments { snapshot2, error2 in
                        guard let docs2 = snapshot2?.documents else { return }
                        let checkOutCount = docs2.filter { ($0.data()["checkOut"] as? Bool) == true }.count
                        let checkOutWaitCount = docs2.filter { ($0.data()["checkOut"] as? Bool) != true }.count

                        self.statItems = [
                            StatItem(title: "오늘 체크인", value: "\(checkInCount)", iconName: "checkmark.circle.fill", iconTintColor: .systemGreen),
                            StatItem(title: "오늘 체크아웃", value: "\(checkOutCount)", iconName: "checkmark.circle.fill", iconTintColor: .systemBlue),
                            StatItem(title: "체크인 대기", value: "\(checkInWaitCount)", iconName: "clock.fill", iconTintColor: .systemOrange),
                            StatItem(title: "체크아웃 대기", value: "\(checkOutWaitCount)", iconName: "clock.fill", iconTintColor: .systemPurple)
                        ]
                        self.updateStatsGrid()
                    }
            }
    }

    // 통계 값이 바뀔 때마다 UI 갱신
    private func updateStatsGrid() {
        // UI 스레드에서 실행
        DispatchQueue.main.async {
            for (index, tuple) in self.statViews.enumerated() {
                if index < self.statItems.count {
                    tuple.valueLabel.text = self.statItems[index].value
                }
            }
        }
    }

    // MARK: - 3) Recent Recognition Section 구성

    private func configureRecentSection() {
        // 헤더 레이블
        recentHeaderLabel.translatesAutoresizingMaskIntoConstraints = false
        recentHeaderLabel.text = "최근 인식 결과"
        recentHeaderLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)

        // 테이블뷰 설정 (스크롤 가능)
        recentTableView.translatesAutoresizingMaskIntoConstraints = false
        recentTableView.dataSource = self
        recentTableView.delegate = self
        recentTableView.register(RecentRecognitionCell.self, forCellReuseIdentifier: RecentRecognitionCell.identifier)
        recentTableView.alwaysBounceVertical = true
        recentTableView.isScrollEnabled = true

        view.addSubview(recentHeaderLabel)
        view.addSubview(recentTableView)

        NSLayoutConstraint.activate([
            // recentHeaderLabel: statsContainer 아래 24pt, 좌/우 16pt
            recentHeaderLabel.topAnchor.constraint(equalTo: statsContainer.bottomAnchor, constant: 24),
            recentHeaderLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            recentHeaderLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            // recentTableView: recentHeaderLabel 아래 8pt, 좌/우 16pt, 하단 safeArea -16
            recentTableView.topAnchor.constraint(equalTo: recentHeaderLabel.bottomAnchor, constant: 8),
            recentTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            recentTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            recentTableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16)
        ])
    }
}

// MARK: - UITableViewDataSource, UITableViewDelegate

extension CheckInViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dummyRecents.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: RecentRecognitionCell.identifier, for: indexPath) as? RecentRecognitionCell else {
            return UITableViewCell()
        }
        let data = dummyRecents[indexPath.row]
        cell.configure(with: data)
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
