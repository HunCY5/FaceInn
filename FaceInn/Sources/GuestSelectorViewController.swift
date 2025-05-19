//
//  GuestSelectorViewController.swift
//  FaceInn
//
//  Created by 신찬솔 on 5/18/25.
//

import UIKit

final class GuestSelectorViewController: UIViewController {

    var onGuestsSelected: ((Int, Int) -> Void)?

    private var adults = 2
    private var childCount = 0

    private let adultLabel = UILabel()
    private let adultCountLabel = UILabel()

    private let childLabel = UILabel()
    private let childCountLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        view.backgroundColor = .white
        view.layer.cornerRadius = 10
        view.layer.shadowOpacity = 0.1
        view.layer.shadowRadius = 4
        view.layer.shadowColor = UIColor.black.cgColor

        let adultTitle = UILabel()
        adultTitle.text = "성인"
        adultTitle.font = .boldSystemFont(ofSize: 14)

        let adultSubtitle = UILabel()
        adultSubtitle.text = "Ages 13+"
        adultSubtitle.font = .systemFont(ofSize: 12)
        adultSubtitle.textColor = .gray

        adultCountLabel.text = "\(adults)"
        adultCountLabel.textAlignment = .center

        let adultMinus = makeCircleButton(title: "-") { [weak self] in
            guard let self = self else { return }
            if self.adults > 1 { self.adults -= 1; self.updateLabels() }
        }

        let adultPlus = makeCircleButton(title: "+") { [weak self] in
            guard let self = self else { return }
            self.adults += 1; self.updateLabels()
        }

        let adultRow = UIStackView(arrangedSubviews: [adultMinus, adultCountLabel, adultPlus])
        adultRow.axis = .horizontal
        adultRow.spacing = 8
        adultRow.distribution = .fillEqually
        adultRow.widthAnchor.constraint(equalToConstant: 70).isActive = true

        let adultStack = UIStackView(arrangedSubviews: [adultTitle, adultSubtitle, adultRow])
        adultStack.axis = .vertical
        adultStack.spacing = 2

        let childTitle = UILabel()
        childTitle.text = "아동"
        childTitle.font = .boldSystemFont(ofSize: 14)

        let childSubtitle = UILabel()
        childSubtitle.text = "Ages 2–12"
        childSubtitle.font = .systemFont(ofSize: 12)
        childSubtitle.textColor = .gray

        childCountLabel.text = "\(childCount)"
        childCountLabel.textAlignment = .center

        let childMinus = makeCircleButton(title: "-") { [weak self] in
            guard let self = self else { return }
            if self.childCount > 0 { self.childCount -= 1; self.updateLabels() }
        }

        let childPlus = makeCircleButton(title: "+") { [weak self] in
            guard let self = self else { return }
            self.childCount += 1; self.updateLabels()
        }

        let childRow = UIStackView(arrangedSubviews: [childMinus, childCountLabel, childPlus])
        childRow.axis = .horizontal
        childRow.spacing = 8
        childRow.distribution = .fillEqually
        childRow.widthAnchor.constraint(equalToConstant: 70).isActive = true

        let childStack = UIStackView(arrangedSubviews: [childTitle, childSubtitle, childRow])
        childStack.axis = .vertical
        childStack.spacing = 6

        let mainStack = UIStackView(arrangedSubviews: [adultStack, childStack])
        mainStack.axis = .vertical
        mainStack.spacing = 10
        mainStack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(mainStack)
        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: view.topAnchor, constant: 12),
            mainStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            mainStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            mainStack.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -12)
        ])
    }

    private func makeCircleButton(title: String, action: @escaping () -> Void) -> UIButton {
        let btn = UIButton(type: .system)
        btn.setTitle(title, for: .normal)
        btn.titleLabel?.font = .boldSystemFont(ofSize: 14)
        let customColor = UIColor(red: 47/255, green: 175/255, blue: 83/255, alpha: 1.0)
        btn.setTitleColor(customColor, for: .normal)
        btn.layer.borderWidth = 1
        btn.layer.borderColor = customColor.cgColor
        btn.layer.cornerRadius = 6
        btn.addAction(UIAction { _ in action() }, for: .touchUpInside)
        btn.widthAnchor.constraint(equalToConstant: 24).isActive = true
        btn.heightAnchor.constraint(equalToConstant: 24).isActive = true
        return btn
    }

    private func updateLabels() {
        adultCountLabel.text = "\(adults)"
        childCountLabel.text = "\(childCount)"
        onGuestsSelected?(adults, childCount)
    }
}
