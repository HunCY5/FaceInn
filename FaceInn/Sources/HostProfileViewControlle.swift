//
//  HostProfileViewControlle.swift
//  FaceInn
//
//  Created by 신찬솔 on 5/21/25.
//


import UIKit

final class HostProfileViewController: UIViewController {

    var hostId: String = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "판매자 정보"
        view.backgroundColor = .white

        let hostIDLabel = UILabel()
        hostIDLabel.text = "Host ID: \(hostId)"
        hostIDLabel.textAlignment = .center
        hostIDLabel.font = UIFont.systemFont(ofSize: 20)
        hostIDLabel.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(hostIDLabel)

        NSLayoutConstraint.activate([
            hostIDLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            hostIDLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
}
