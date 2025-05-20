//
//  AccommodationDetailViewController .swift
//  FaceInn
//
//  Created by 신찬솔 on 5/20/25.
//

import UIKit

final class AccommodationDetailViewController: UIViewController {

    var accommodation: Accommodation?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        self.hidesBottomBarWhenPushed = true
        self.title = accommodation?.name


        let label = UILabel()
        label.text = "숙소 상세 페이지"
        label.font = .systemFont(ofSize: 18)
        label.textColor = .black
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)

        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
}
