//
//  HomeViewController.swift
//  FaceInn
//
//  Created by 신찬솔 on 5/18/25.
//

import UIKit
import FirebaseFirestore
import FirebaseStorage

final class HomeViewController: UIViewController {

    private let appTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "FaceInn"
        label.font = UIFont.boldSystemFont(ofSize: 24)
        label.textColor = UIColor.black
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let searchBar: UISearchBar = {
        let sb = UISearchBar()
        sb.placeholder = "Search destinations, hotels..."
        sb.searchBarStyle = .minimal
        sb.backgroundImage = UIImage() // remove border
        sb.translatesAutoresizingMaskIntoConstraints = false
        return sb
    }()

    private let filterStackView: UIStackView = {
        let locationButton = UIButton(type: .system)
        locationButton.setTitle("📍 위치", for: .normal)
        locationButton.contentHorizontalAlignment = .center
        locationButton.tintColor = .black
        locationButton.layer.cornerRadius = 8
        locationButton.layer.borderWidth = 1
        locationButton.layer.borderColor = UIColor(red: 47/255, green: 175/255, blue: 83/255, alpha: 1).cgColor
        locationButton.backgroundColor = .white
        locationButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        locationButton.contentEdgeInsets = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        locationButton.widthAnchor.constraint(equalToConstant: 85).isActive = true
        locationButton.addTarget(self, action: #selector(locationButtonTapped(_:)), for: .touchUpInside)

        let dateButton = UIButton(type: .system)
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M월 d일"
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        let title = "📅 \(formatter.string(from: Date())) - \(formatter.string(from: tomorrow))"
        dateButton.setTitle(title, for: .normal)
        dateButton.contentHorizontalAlignment = .center
        dateButton.tintColor = .black
        dateButton.layer.cornerRadius = 8
        dateButton.layer.borderWidth = 1
        dateButton.layer.borderColor = UIColor(red: 47/255, green: 175/255, blue: 83/255, alpha: 1).cgColor
        dateButton.backgroundColor = .white
        dateButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        dateButton.contentEdgeInsets = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        dateButton.widthAnchor.constraint(equalToConstant: 150).isActive = true

        let guestButton = UIButton(type: .system)
        guestButton.setTitle("👥 2명", for: .normal)
        guestButton.contentHorizontalAlignment = .center
        guestButton.tintColor = .black
        guestButton.layer.cornerRadius = 8
        guestButton.layer.borderWidth = 1
        guestButton.layer.borderColor = UIColor(red: 47/255, green: 175/255, blue: 83/255, alpha: 1).cgColor
        guestButton.backgroundColor = .white
        guestButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        guestButton.contentEdgeInsets = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        guestButton.widthAnchor.constraint(equalToConstant: 85).isActive = true
        guestButton.addTarget(self, action: #selector(guestButtonTapped(_:)), for: .touchUpInside)
        

        let stack = UIStackView(arrangedSubviews: [locationButton, dateButton, guestButton])
        stack.axis = .horizontal
        stack.distribution = .fill
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private var accommodations: [Accommodation] = []
    private var filteredAccommodations: [Accommodation] = []

    private let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 16
        layout.sectionInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        layout.itemSize = CGSize(width: UIScreen.main.bounds.width - 32, height: 330)
        return UICollectionView(frame: .zero, collectionViewLayout: layout)
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupLayout()
        setupCollectionView()
        searchBar.delegate = self
        fetchAccommodations()
        if let locationButton = filterStackView.arrangedSubviews[0] as? UIButton {
            let savedLocation = UserDefaults.standard.string(forKey: "selectedLocation") ?? "위치"
            locationButton.setTitle("📍 \(savedLocation)", for: .normal)
        }

        if let dateButton = filterStackView.arrangedSubviews[1] as? UIButton {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "ko_KR")
            formatter.dateFormat = "M월 d일"
            if let start = UserDefaults.standard.object(forKey: "selectedStartDate") as? Date,
               let end = UserDefaults.standard.object(forKey: "selectedEndDate") as? Date {
                let title = "📅 \(formatter.string(from: start)) - \(formatter.string(from: end))"
                dateButton.setTitle(title, for: .normal)
            }
        }

        if let guestButton = filterStackView.arrangedSubviews[2] as? UIButton {
            let savedGuestCount = UserDefaults.standard.object(forKey: "selectedGuestCount") != nil ?
                UserDefaults.standard.integer(forKey: "selectedGuestCount") : 2
            guestButton.setTitle("👥 \(savedGuestCount)명", for: .normal)
        }

        if let dateButton = filterStackView.arrangedSubviews[1] as? UIButton {
            dateButton.addTarget(self, action: #selector(dateButtonTapped(_:)), for: .touchUpInside)
        }
        setupKeyboardDismissal()
        addDoneButtonOnKeyboard()
        NotificationCenter.default.addObserver(self, selector: #selector(handleAuthChanged), name: .AuthStateDidChange, object: nil)
    }

@objc private func handleAuthChanged() {
    collectionView.reloadData()
}

    private func addDoneButtonOnKeyboard() {
        let doneToolbar: UIToolbar = UIToolbar()
        doneToolbar.sizeToFit()
        
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let done: UIBarButtonItem = UIBarButtonItem(title: "닫기", style: .done, target: self, action: #selector(dismissKeyboard))
        
        doneToolbar.items = [flexSpace, done]
        doneToolbar.isUserInteractionEnabled = true
        searchBar.inputAccessoryView = doneToolbar
    }

    @objc private func guestButtonTapped(_ sender: UIButton) {
        let vc = GuestSelectorViewController()
        vc.modalPresentationStyle = .popover
        vc.preferredContentSize = CGSize(width: 220, height: 160)
        vc.onGuestsSelected = { [weak self] adults, children in
            let totalGuests = adults + children
            sender.setTitle("👥 \(totalGuests)명", for: .normal)
            UserDefaults.standard.set(totalGuests, forKey: "selectedGuestCount")
            self?.fetchAccommodations()
        }

        if let popover = vc.popoverPresentationController {
            popover.sourceView = sender
            popover.sourceRect = sender.bounds
            popover.permittedArrowDirections = .up
            popover.delegate = self
        }
        present(vc, animated: true)
    }
    
    @objc private func locationButtonTapped(_ sender: UIButton) {
        let vc = LocationSelectorViewController()
        vc.modalPresentationStyle = .popover
        vc.preferredContentSize = CGSize(width: 220, height: 160)
        vc.onLocationSelected = { [weak self] location in
            sender.setTitle("📍 \(location)", for: .normal)
            UserDefaults.standard.set(location, forKey: "selectedLocation")
            if location == "위치" {
                self?.filteredAccommodations = self?.accommodations ?? []
            } else {
                self?.filteredAccommodations = self?.accommodations.filter {
                    $0.location.localizedCaseInsensitiveContains(location)
                } ?? []
            }
            self?.collectionView.reloadData()
        }

        if let popover = vc.popoverPresentationController {
            popover.sourceView = sender
            popover.sourceRect = sender.bounds
            popover.permittedArrowDirections = .up
            popover.delegate = self
        }

        present(vc, animated: true)
    }

    @objc private func dateButtonTapped(_ sender: UIButton) {
        let vc = DatePickerPopoverViewController()
        vc.modalPresentationStyle = .popover
        vc.preferredContentSize = CGSize(width: 280, height: 300)
        vc.onDateSelected = { [weak self] startDate, endDate in
            guard let self else { return }
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "ko_KR")
            formatter.dateFormat = "M월 d일"
            if let start = startDate, let end = endDate {
                let title = "📅 \(formatter.string(from: start)) - \(formatter.string(from: end))"
                sender.setTitle(title, for: .normal)
            } else if let start = startDate {
                let title = "📅 \(formatter.string(from: start))"
                sender.setTitle(title, for: .normal)
            }
            self.fetchAccommodations()
        }

        if let popover = vc.popoverPresentationController {
            popover.sourceView = sender
            popover.sourceRect = sender.bounds
            popover.permittedArrowDirections = .up
            popover.delegate = self
        }
        present(vc, animated: true)
    }

    private func setupLayout() {
        view.backgroundColor = .systemBackground

        let topStack = UIStackView(arrangedSubviews: [searchBar, filterStackView])
        topStack.axis = .vertical
        topStack.spacing = 6
        topStack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(appTitleLabel)
        view.addSubview(topStack)
        view.addSubview(collectionView)

        topStack.translatesAutoresizingMaskIntoConstraints = false
        collectionView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            appTitleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            appTitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),

            topStack.topAnchor.constraint(equalTo: appTitleLabel.bottomAnchor, constant: 8),
            topStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            topStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            collectionView.topAnchor.constraint(equalTo: topStack.bottomAnchor, constant: 16),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }

    private func setupCollectionView() {
        collectionView.dataSource = self
        collectionView.register(AccommodationCell.self, forCellWithReuseIdentifier: AccommodationCell.identifier)
    }

    private func fetchAccommodations() {
        Firestore.firestore().collection("accommodations").getDocuments { [weak self] snapshot, error in
            guard let self = self, let documents = snapshot?.documents else { return }
            self.accommodations = documents.compactMap { doc -> Accommodation? in
                let data = doc.data()
                return Accommodation(
                    id: doc.documentID,
                    name: data["name"] as? String ?? "",
                    location: data["location"] as? String ?? "",
                    price: data["price"] as? Int ?? 0,
                    rating: data["rating"] as? Double ?? 0.0,
                    reviewCount: data["reviewCount"] as? Int ?? 0,
                    imageURLs: data["imageURLs"] as? [String],
                    rooms: data["rooms"] as? [[String: Any]]
                )
            }
            let guestCount = UserDefaults.standard.object(forKey: "selectedGuestCount") != nil ?
                UserDefaults.standard.integer(forKey: "selectedGuestCount") : 2

            self.filteredAccommodations = self.accommodations.filter { accommodation in
                guard let rooms = accommodation.rooms else { return false }
                // 해당 호텔의 rooms 중 하나라도 guestCount 이상 수용 가능한 객실이 있어야 포함
                return rooms.contains { room in
                    if let maxOccupancy = room["maxOccupancy"] as? Int {
                        return maxOccupancy >= guestCount
                    }
                    return false
                }
            }
            DispatchQueue.main.async {
                let section = IndexSet(integer: 0)
                self.collectionView.reloadSections(section)
            }
        }
    }

    private func setupKeyboardDismissal() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
}

extension HomeViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return filteredAccommodations.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: AccommodationCell.identifier, for: indexPath) as? AccommodationCell else {
            return UICollectionViewCell()
        }
        cell.configure(with: filteredAccommodations[indexPath.item])
        cell.onCardTapped = { [weak self] in
            guard let self = self else { return }
            let accommodation = self.filteredAccommodations[indexPath.item]
            let detailVC = AccommodationDetailViewController()
            detailVC.accommodation = accommodation
            self.navigationController?.pushViewController(detailVC, animated: true)
        }
        // 로그인 후 찜 기능 연계
        cell.onLikeRequested = { [weak self] in
            guard let self = self else { return }
            let alert = UIAlertController(title: "로그인이 필요합니다", message: "찜 기능은 로그인 후 사용 가능합니다.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "로그인", style: .default, handler: { _ in
                let loginVC = LoginViewController()
                loginVC.onLoginSuccess = { [weak self] in
                    if cell.isLiked == false {
                        cell.toggleLike()
                        self?.collectionView.reloadData()
                    } else {
                        self?.collectionView.reloadData()
                    }
                }
                self.navigationController?.pushViewController(loginVC, animated: true)
            }))
            alert.addAction(UIAlertAction(title: "취소", style: .cancel))
            self.present(alert, animated: true)
        }
        return cell
    }
}

extension HomeViewController: UIPopoverPresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
}

extension HomeViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            filteredAccommodations = accommodations
        } else {
            filteredAccommodations = accommodations.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.location.localizedCaseInsensitiveContains(searchText)
            }
        }
        collectionView.reloadData()
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}


extension Notification.Name {
    static let AuthStateDidChange = Notification.Name("AuthStateDidChange")
}
