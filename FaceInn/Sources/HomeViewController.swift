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
        locationButton.setTitle("📍 Location", for: .normal)
        locationButton.contentHorizontalAlignment = .left
        locationButton.layer.cornerRadius = 8
        locationButton.layer.borderWidth = 1
        locationButton.layer.borderColor = UIColor.systemGray4.cgColor
        locationButton.backgroundColor = .white
        locationButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        locationButton.contentEdgeInsets = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)

        let dateButton = UIButton(type: .system)
        dateButton.setTitle("📅 Dates", for: .normal)
        dateButton.contentHorizontalAlignment = .left
        dateButton.layer.cornerRadius = 8
        dateButton.layer.borderWidth = 1
        dateButton.layer.borderColor = UIColor.systemGray4.cgColor
        dateButton.backgroundColor = .white
        dateButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        dateButton.contentEdgeInsets = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)

        let guestButton = UIButton(type: .system)
        guestButton.setTitle("👥 Guests", for: .normal)
        guestButton.contentHorizontalAlignment = .left
        guestButton.layer.cornerRadius = 8
        guestButton.layer.borderWidth = 1
        guestButton.layer.borderColor = UIColor.systemGray4.cgColor
        guestButton.backgroundColor = .white
        guestButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        guestButton.contentEdgeInsets = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)

        let stack = UIStackView(arrangedSubviews: [locationButton, dateButton, guestButton])
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private var accommodations: [Accommodation] = []

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
        fetchAccommodations()
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
            DispatchQueue.main.async {
                self.collectionView.reloadData()
            }
        }
    }
}

extension HomeViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return accommodations.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: AccommodationCell.identifier, for: indexPath) as? AccommodationCell else {
            return UICollectionViewCell()
        }
        cell.configure(with: accommodations[indexPath.item])
        return cell
    }
}
