//
//  WishlistViewController.swift
//  FaceInn
//
//  Created by 신찬솔 on 5/18/25.
//

import UIKit
import FirebaseFirestore
import FirebaseAuth

final class WishlistViewController: UIViewController {

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
        self.title = "찜목록"
        view.backgroundColor = .white

        collectionView.dataSource = self
        collectionView.register(AccommodationCell.self, forCellWithReuseIdentifier: AccommodationCell.identifier)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collectionView)

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])

        NotificationCenter.default.addObserver(self, selector: #selector(reloadWishlist), name: .userDidLogin, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(reloadWishlist), name: .AuthStateDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(reloadWishlist), name: .didToggleWishlist, object: nil)

        loadWishlist()
    }

    @objc private func reloadWishlist() {
        filteredAccommodations.removeAll()
        loadWishlist()
    }

    private func loadWishlist() {
        // Remove any login label if present
        view.subviews.filter { $0 is UILabel && ($0 as? UILabel)?.text == "로그인 후 이용해주세요" }.forEach { $0.removeFromSuperview() }

        guard let user = Auth.auth().currentUser, !user.isAnonymous else {
            view.subviews.filter { $0 is UILabel && ($0 as? UILabel)?.text == "숙소를 검색하고 찜목록에 추가하세요" }.forEach { $0.removeFromSuperview() }

            let label = UILabel()
            label.text = "로그인 후 이용해주세요"
            label.textAlignment = .center
            label.font = .systemFont(ofSize: 18, weight: .medium)
            label.textColor = .gray
            label.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(label)

            NSLayoutConstraint.activate([
                label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
            ])
            filteredAccommodations.removeAll()
            collectionView.reloadData()
            return
        }

        let userRef = Firestore.firestore().collection("users").document(user.uid)
        userRef.getDocument { snapshot, error in
            guard let data = snapshot?.data(),
                  let wishlist = data["wishList"] as? [String] else {
                print("위시리스트 데이터를 가져오지 못함")
                DispatchQueue.main.async {
                    self.filteredAccommodations.removeAll()
                    self.collectionView.reloadData()
                }
                return
            }

            let group = DispatchGroup()
            var loadedAccommodations: [Accommodation] = []

            for id in wishlist {
                group.enter()
                Firestore.firestore().collection("accommodations").document(id).getDocument { snapshot, error in
                    defer { group.leave() }
                    guard let data = snapshot?.data() else { return }

                    let accommodation = Accommodation(
                        id: id,
                        name: data["name"] as? String ?? "",
                        location: data["location"] as? String ?? "",
                        price: data["price"] as? Int ?? 0,
                        rating: data["rating"] as? Double ?? 0.0,
                        reviewCount: data["reviewCount"] as? Int ?? 0,
                        imageURLs: data["imageURLs"] as? [String],
                        rooms: data["rooms"] as? [[String: Any]],
                        amenities: data["amenities"] as? [String],
                        description: data["description"] as? String ?? "",
                        hostId: data["hostId"] as? String ?? ""
                    )
                    loadedAccommodations.append(accommodation)
                }
            }

            group.notify(queue: .main) {
                // Remove any existing info label before adding a new one
                self.view.subviews.filter { $0 is UILabel && ($0 as? UILabel)?.text == "숙소를 검색하고 찜목록에 추가하세요" }.forEach { $0.removeFromSuperview() }

                self.filteredAccommodations = loadedAccommodations
                self.collectionView.reloadData()
                if wishlist.isEmpty {
                    let label = UILabel()
                    label.text = "숙소를 검색하고 찜목록에 추가하세요"
                    label.textAlignment = .center
                    label.font = .systemFont(ofSize: 18, weight: .medium)
                    label.textColor = .gray
                    label.translatesAutoresizingMaskIntoConstraints = false
                    self.view.addSubview(label)

                    NSLayoutConstraint.activate([
                        label.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
                        label.centerYAnchor.constraint(equalTo: self.view.centerYAnchor)
                    ])
                }
            }
        }
    }
}

extension WishlistViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return filteredAccommodations.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: AccommodationCell.identifier, for: indexPath) as? AccommodationCell else {
            return UICollectionViewCell()
        }
        cell.configure(with: filteredAccommodations[indexPath.item])
        cell.onLikeChanged = {
            NotificationCenter.default.post(name: .AuthStateDidChange, object: nil)
        }
        cell.onCardTapped = { [weak self] in
            guard let self = self else { return }
            let accommodation = self.filteredAccommodations[indexPath.item]
            let detailVC = AccommodationDetailViewController()
            detailVC.accommodation = accommodation
            self.navigationController?.pushViewController(detailVC, animated: true)
        }
        return cell
    }
}

// MARK: - Notification.Name Extension
extension Notification.Name {
    static let didToggleWishlist = Notification.Name("didToggleWishlist")
}
