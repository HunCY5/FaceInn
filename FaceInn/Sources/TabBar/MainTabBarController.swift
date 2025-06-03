//
//  MainTabBarController.swift
//  FaceInn
//
//  Created by 신찬솔 on 5/18/25.
//

import UIKit

final class MainTabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        tabBar.tintColor = UIColor(red: 47/255, green: 175/255, blue: 83/255, alpha: 1)
        setupTabs()
    }

    private func setupTabs() {
        let homeVC = UINavigationController(rootViewController: HomeViewController())
        homeVC.tabBarItem = UITabBarItem(title: "홈", image: UIImage(systemName: "house"), tag: 0)

        let wishlistVC = UINavigationController(rootViewController: WishlistViewController())
        wishlistVC.tabBarItem = UITabBarItem(title: "찜", image: UIImage(systemName: "heart"), tag: 1)

        let tripsVC = UINavigationController(rootViewController: TripsViewController())
        tripsVC.tabBarItem = UITabBarItem(title: "여행", image: UIImage(systemName: "airplane"), tag: 2)

//        let messageVC = UINavigationController(rootViewController: MessageViewController())
//        messageVC.tabBarItem = UITabBarItem(title: "메시지", image: UIImage(systemName: "message"), tag: 3)

        let profileVC = UINavigationController(rootViewController: ProfileViewController())
        profileVC.tabBarItem = UITabBarItem(title: "프로필", image: UIImage(systemName: "person"), tag: 3)

        viewControllers = [homeVC, wishlistVC, tripsVC/*, messageVC*/, profileVC]
    }
}
