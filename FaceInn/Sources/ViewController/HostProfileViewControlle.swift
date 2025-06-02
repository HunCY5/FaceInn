//
//  HostProfileViewControlle.swift
//  FaceInn
//
//  Created by 신찬솔 on 5/21/25.
//

import UIKit
import FirebaseFirestore
import FirebaseAuth

final class HostProfileViewController: UIViewController {

    var hostId: String = ""
    var accommodationName: String = ""
    var accommodationAddress: String = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "판매자 정보"
        view.backgroundColor = .white

        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 24
        stackView.alignment = .fill
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 48),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32)
        ])

        let titles = ["상호", "대표자명", "주소", "전화번호", "이메일", "사업자번호"]
        var valueLabels: [UILabel] = []

        for i in 0..<titles.count {
            let rowStack = UIStackView()
            rowStack.axis = .horizontal
            rowStack.spacing = 8
            rowStack.distribution = .fill

            let titleLabel = UILabel()
            titleLabel.text = titles[i]
            titleLabel.textColor = UIColor.lightGray
            titleLabel.font = UIFont.boldSystemFont(ofSize: 16)
            titleLabel.setContentHuggingPriority(.required, for: .horizontal)
            titleLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

            let valueLabel = UILabel()
            valueLabel.textColor = UIColor.black
            valueLabel.font = UIFont.systemFont(ofSize: 16)
            valueLabel.numberOfLines = 0
            valueLabel.textAlignment = .right
            valueLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
            valueLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

            
            switch titles[i] {
            case "상호":
                valueLabel.text = self.accommodationName
            case "주소":
                valueLabel.text = self.accommodationAddress
            default:
                valueLabel.text = ""
            }

            valueLabels.append(valueLabel)

            rowStack.addArrangedSubview(titleLabel)
            rowStack.addArrangedSubview(valueLabel)

            stackView.addArrangedSubview(rowStack)
        }

        // Firestore에서 hostId 기반으로 조회
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(hostId)
        userRef.getDocument { userSnap, err in
            guard let userData = userSnap?.data() else { return }
            let ceo = userData["name"] as? String ?? "-"
            let phone = userData["phone"] as? String ?? "-"
            let email = userData["email"] as? String ?? "-"
            let bizNum = userData["businessNumber"] as? String ?? "-"

            DispatchQueue.main.async {
                // "대표자명" is at index 1
                valueLabels[1].text = ceo
                // "전화번호" is at index 3
                valueLabels[3].text = phone
                // "이메일" is at index 4
                valueLabels[4].text = email
                // "사업자번호" is at index 5
                valueLabels[5].text = bizNum
            }
        }

        let disclaimerLabel = UILabel()
        disclaimerLabel.numberOfLines = 0

        let redBoldAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.red,
            .font: UIFont.boldSystemFont(ofSize: 16)
        ]
        let blackAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.black,
            .font: UIFont.systemFont(ofSize: 16)
        ]

        let disclaimerText = NSMutableAttributedString(string: "판매자 정보는 FaceInn에서 직접 검증하지 않습니다.\n", attributes: redBoldAttributes)
        disclaimerText.append(NSAttributedString(string: "거래 전 반드시 판매자와 직접 연락하여 확인하시기 바랍니다.", attributes: blackAttributes))

        disclaimerLabel.attributedText = disclaimerText
        disclaimerLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(disclaimerLabel)

        NSLayoutConstraint.activate([
            disclaimerLabel.topAnchor.constraint(equalTo: stackView.bottomAnchor, constant: 24),
            disclaimerLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            disclaimerLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32)
        ])
    }
}
