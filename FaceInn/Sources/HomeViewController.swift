//
//  HomeViewController.swift
//  FaceInn
//
//  Created by 신찬솔 on 5/18/25.
//

import UIKit
import FirebaseFirestore

final class HomeViewController: UIViewController {

    private let searchBar: UISearchBar = {
        let sb = UISearchBar()
        sb.placeholder = "숙소 이름 검색"
        return sb
    }()

    private let filterStackView: UIStackView = {
        let locationButton = UIButton(type: .system)
        locationButton.setTitle("지역 선택", for: .normal)

        let dateButton = UIButton(type: .system)
        dateButton.setTitle("날짜 선택", for: .normal)

        let guestButton = UIButton(type: .system)
        guestButton.setTitle("인원 선택", for: .normal)

        let stack = UIStackView(arrangedSubviews: [locationButton, dateButton, guestButton])
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = 8
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
//        #if DEBUG
//        let docRef = Firestore.firestore().collection("accommodations").document("shilla_copy")
//        docRef.getDocument { snapshot, error in
//            if let snapshot = snapshot, !snapshot.exists {
//                AccommodationSeeder.seedShillaHotel()
//            } else {
//                print("✅ 'shilla' 문서가 이미 존재하므로 시드 생략")
//            }
//        }
//        // Insert a copy with a different document ID just after seeding 'shilla'
//        let docRef2 = Firestore.firestore().collection("accommodations").document("shilla_copy")
//        docRef2.getDocument { snapshot, error in
//            if let snapshot = snapshot, !snapshot.exists {
//                AccommodationSeeder.seedShillaHotel(docId: "shilla_copy")
//            }
//        }
//        #endif
//        view.backgroundColor = .systemBackground
        setupLayout()
        setupCollectionView()
        fetchAccommodations()
    }

    private func setupLayout() {
        let topStack = UIStackView(arrangedSubviews: [searchBar, filterStackView])
        topStack.axis = .vertical
        topStack.spacing = 12
        view.addSubview(topStack)
        view.addSubview(collectionView)

        topStack.translatesAutoresizingMaskIntoConstraints = false
        collectionView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            topStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            topStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            topStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            collectionView.topAnchor.constraint(equalTo: topStack.bottomAnchor, constant: 16),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
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
