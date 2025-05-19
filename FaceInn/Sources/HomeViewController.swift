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
        if let dateButton = filterStackView.arrangedSubviews[1] as? UIButton {
            dateButton.addTarget(self, action: #selector(dateButtonTapped(_:)), for: .touchUpInside)
        }
    }

    @objc private func guestButtonTapped(_ sender: UIButton) {
        let vc = GuestSelectorViewController()
        vc.modalPresentationStyle = .popover
        vc.preferredContentSize = CGSize(width: 220, height: 160)
        vc.onGuestsSelected = { [weak self] adults, children in
            sender.setTitle("👥 \(adults + children)명", for: .normal)
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

        view.addSubview(topStack)
        view.addSubview(collectionView)

        topStack.translatesAutoresizingMaskIntoConstraints = false
        collectionView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            topStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
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
                    imageURLs: data["imageURLs"] as? [String]
                )
            }
            self.filteredAccommodations = self.accommodations
            DispatchQueue.main.async {
                self.collectionView.reloadData()
            }
        }
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
}
