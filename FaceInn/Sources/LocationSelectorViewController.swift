//
//  LocationSelectorViewController.swift
//  FaceInn
//
//  Created by 신찬솔 on 5/20/25.
//

import UIKit

final class LocationSelectorViewController: UIViewController {
    var onLocationSelected: ((String) -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        view.layer.cornerRadius = 12

        let titleLabel = UILabel()
        titleLabel.text = "인기 지역"
        titleLabel.font = UIFont.boldSystemFont(ofSize: 16)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        let locations = ["서울", "부산", "제주", "강릉"]
        let buttons = locations.map { location -> UIButton in
            let button = UIButton(type: .system)
            button.setTitle(location, for: .normal)
            button.setTitleColor(.black, for: .normal)
            button.layer.borderWidth = 1
            button.layer.borderColor = UIColor(red: 47/255, green: 175/255, blue: 83/255, alpha: 1.0).cgColor
            button.layer.cornerRadius = 6
            button.titleLabel?.font = .systemFont(ofSize: 14)
            button.backgroundColor = .white
            button.addTarget(self, action: #selector(locationTapped(_:)), for: .touchUpInside)
            return button
        }

        let grid = UIStackView()
        grid.axis = .vertical
        grid.spacing = 8
        grid.translatesAutoresizingMaskIntoConstraints = false

        for i in stride(from: 0, to: buttons.count, by: 2) {
            let row = UIStackView(arrangedSubviews: Array(buttons[i..<min(i+2, buttons.count)]))
            row.axis = .horizontal
            row.distribution = .fillEqually
            row.spacing = 8
            grid.addArrangedSubview(row)
        }

        let stack = UIStackView(arrangedSubviews: [titleLabel, grid])
        stack.axis = .vertical
        stack.spacing = 6
        stack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -16)
        ])
    }

    @objc private func locationTapped(_ sender: UIButton) {
        guard let title = sender.currentTitle else { return }
        onLocationSelected?(title)
        dismiss(animated: true)
    }
}
