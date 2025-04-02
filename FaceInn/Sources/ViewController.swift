//
//  ViewController.swift
//  FaceInn
//
//  Created by CHOI on 3/31/25.
//

import UIKit

class ViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        print("✅ ViewController.viewDidLoad 실행됨")

        view.backgroundColor = .systemBackground

        let label = UILabel()
        label.text = "👋 Hello, UIKit!"
        label.textColor = .label
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(label)

        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
}
