//
//  HostMainTabBarController.swift
//  FaceInn
//
//  Created by CHOI on 5/28/25.
//

import UIKit

final class HostMainTabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // 탭 아이템 선택 색상
        tabBar.tintColor = UIColor(red: 47/255, green: 175/255, blue: 83/255, alpha: 1)
        setupTabs()
    }

    private func setupTabs() {
        // 1) 예약관리 탭
        let manageReservationNav = UINavigationController(
            rootViewController: ManageReservationViewController()
        )
        manageReservationNav.tabBarItem = UITabBarItem(
            title: "예약관리",
            image: UIImage(systemName: "calendar"),
            tag: 0
        )

        // 2) 체크인 탭
        let checkInNav = UINavigationController(
            rootViewController: CheckInViewController()
        )
        checkInNav.tabBarItem = UITabBarItem(
            title: "체크인",
            image: UIImage(systemName: "camera"),
            tag: 1
        )

        // 3) 객실관리 탭
        let manageRoomNav = UINavigationController(
            rootViewController: ManageRoomViewController()
        )
        manageRoomNav.tabBarItem = UITabBarItem(
            title: "객실관리",
            image: UIImage(systemName: "bed.double"),
            tag: 2
        )

        // 4) 마이페이지 탭
        let hostProfileNav = UINavigationController(
            rootViewController: HostPageViewController()
        )
        hostProfileNav.tabBarItem = UITabBarItem(
            title: "마이페이지",
            image: UIImage(systemName: "person"),
            tag: 3
        )

        viewControllers = [
            manageReservationNav,
            checkInNav,
            manageRoomNav,
            hostProfileNav
        ]
    }
}
