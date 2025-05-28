//
//  ManageReservationViewController.swift
//  FaceInn
//
//  Created by CHOI on 5/28/25.
//

import UIKit
final class ManageReservationViewController: UIViewController{
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        let label = UILabel()
        label.text = "예약 관리 뷰"
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 24)
        label.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
}
