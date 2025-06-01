//
//  HostProfileView.swift
//  FaceInn
//
//  Created by 신찬솔 on 5/31/25.
//


import UIKit

final class HostPageView: UIView {
    // MARK: - UI 요소
    var loginButton: UIButton!
    var faceIDLoginButton: UIButton!
    var logoutButton: UIButton!
    var hostLoginButton: UIButton!
    let nameLabel = UILabel()
    let emailLabel = UILabel()
    let phoneLabel = UILabel()
    let addressLabel = UILabel()
    let verificationLabel = UILabel()
    let editButton = UIButton(type: .system)
    let supportStack = UIStackView()
    let termsButton = UIButton(type: .system)
    let privacyButton = UIButton(type: .system)
    let inquiryButton = UIButton(type: .system)
    let editAccommodationButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("🏨  숙소 정보 수정", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor(red: 0x2f/255, green: 0xaf/255, blue: 0x53/255, alpha: 1)
        button.layer.cornerRadius = 6
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    // MARK: - Stacks
    let guestViewStack = UIStackView()
    let userViewStack = UIStackView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .systemBackground
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - 전체 뷰 구성
    private func setupViews() {
        let contentStack = UIStackView()
        contentStack.axis = .vertical
        contentStack.spacing = 24
        contentStack.isLayoutMarginsRelativeArrangement = true
        contentStack.layoutMargins = UIEdgeInsets(top: 24, left: 20, bottom: 24, right: 20)
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentStack)

        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            contentStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentStack.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])

        setupUserView()
        contentStack.addArrangedSubview(userViewStack)
    }


    // MARK: - User View: 구성요소 및 로그인 후 화면 UI 설정
    private func setupUserView() {
        userViewStack.axis = .vertical
        userViewStack.spacing = 24
        userViewStack.alignment = .fill
        userViewStack.translatesAutoresizingMaskIntoConstraints = false

        // 프로필 이미지 및 이름/이메일
        let userInfoContainer = UIView()
        userInfoContainer.backgroundColor = .white
        userInfoContainer.layer.cornerRadius = 12
        userInfoContainer.layer.borderWidth = 1
        userInfoContainer.layer.borderColor = UIColor.systemGray4.cgColor
        userInfoContainer.translatesAutoresizingMaskIntoConstraints = false

        let userInfoStack = UIStackView()
        userInfoStack.axis = .vertical
        userInfoStack.spacing = 16
        userInfoStack.alignment = .leading
        userInfoStack.translatesAutoresizingMaskIntoConstraints = false
        userInfoContainer.addSubview(userInfoStack)

        NSLayoutConstraint.activate([
            userInfoStack.topAnchor.constraint(equalTo: userInfoContainer.topAnchor, constant: 24),
            userInfoStack.leadingAnchor.constraint(equalTo: userInfoContainer.leadingAnchor, constant: 20),
            userInfoStack.trailingAnchor.constraint(equalTo: userInfoContainer.trailingAnchor, constant: -20),
            userInfoStack.bottomAnchor.constraint(equalTo: userInfoContainer.bottomAnchor, constant: -24)
        ])

        nameLabel.font = .boldSystemFont(ofSize: 20)
        emailLabel.font = .systemFont(ofSize: 14)
        emailLabel.textColor = .gray

        // 로그아웃 버튼
        logoutButton = UIButton(type: .system)
        logoutButton.setImage(UIImage(systemName: "arrow.right.square"), for: .normal)
        logoutButton.tintColor = .white
        logoutButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 0)
        logoutButton.setTitle("로그아웃", for: .normal)
        logoutButton.setTitleColor(.white, for: .normal)
        logoutButton.backgroundColor = UIColor(red: 0x2f/255, green: 0xaf/255, blue: 0x53/255, alpha: 1)
        logoutButton.layer.cornerRadius = 6
        logoutButton.contentEdgeInsets = UIEdgeInsets(top: 10, left: 20, bottom: 10, right: 20)
        logoutButton.contentHorizontalAlignment = .center

        // 프로필 이미지 및 이름/이메일
        let profileImage = UIImageView(image: UIImage(systemName: "person.crop.circle.fill"))
        profileImage.contentMode = .scaleAspectFit
        profileImage.layer.cornerRadius = 24
        profileImage.clipsToBounds = true
        profileImage.translatesAutoresizingMaskIntoConstraints = false
        profileImage.widthAnchor.constraint(equalToConstant: 48).isActive = true
        profileImage.heightAnchor.constraint(equalToConstant: 48).isActive = true

        let nameEmailStack = UIStackView(arrangedSubviews: [nameLabel, emailLabel])
        nameEmailStack.axis = .vertical
        nameEmailStack.spacing = 4

        let profileHeader = UIStackView(arrangedSubviews: [profileImage, nameEmailStack])
        profileHeader.axis = .horizontal
        profileHeader.spacing = 12
        profileHeader.alignment = .center

        userInfoStack.addArrangedSubview(profileHeader)

        // 전화번호, 주소, 본인 인증 정보 표시
        func createIconLabelRow(iconName: String, text: String) -> UIStackView {
            let icon = UIImageView(image: UIImage(systemName: iconName))
            icon.tintColor = .gray
            icon.translatesAutoresizingMaskIntoConstraints = false
            icon.widthAnchor.constraint(equalToConstant: 20).isActive = true
            icon.heightAnchor.constraint(equalToConstant: 20).isActive = true

            let label = UILabel()
            label.text = text
            label.font = .systemFont(ofSize: 14)
            label.textColor = .gray

            let row = UIStackView(arrangedSubviews: [icon, label])
            row.axis = .horizontal
            row.spacing = 8
            return row
        }

        let phoneRow = createIconLabelRow(iconName: "phone.fill", text: "010-1234-5678")
        let addressRow = createIconLabelRow(iconName: "mappin.and.ellipse", text: "서울특별시 강남구")
        let verificationRow = createIconLabelRow(iconName: "checkmark.circle", text: "본인 인증 완료")
        verificationRow.translatesAutoresizingMaskIntoConstraints = false

        userInfoStack.addArrangedSubview(phoneRow)
        userInfoStack.addArrangedSubview(addressRow)
        userInfoStack.addArrangedSubview(verificationRow)

        // 내 정보 수정 버튼
        editButton.setTitle("⚙️  내 정보 수정", for: .normal)
        editButton.setTitleColor(.white, for: .normal)
        editButton.backgroundColor = UIColor(red: 0x2f/255, green: 0xaf/255, blue: 0x53/255, alpha: 1)
        editButton.layer.cornerRadius = 6
        editButton.translatesAutoresizingMaskIntoConstraints = false
        userInfoContainer.addSubview(editButton)

        userInfoContainer.addSubview(editAccommodationButton)

        let buttonsStack = UIStackView(arrangedSubviews: [editAccommodationButton, editButton])
        buttonsStack.axis = .horizontal
        buttonsStack.distribution = .fillEqually
        buttonsStack.spacing = 12
        buttonsStack.translatesAutoresizingMaskIntoConstraints = false
        userInfoContainer.addSubview(buttonsStack)

        NSLayoutConstraint.activate([
            buttonsStack.leadingAnchor.constraint(equalTo: userInfoContainer.leadingAnchor, constant: 20),
            buttonsStack.trailingAnchor.constraint(equalTo: userInfoContainer.trailingAnchor, constant: -20),
            buttonsStack.topAnchor.constraint(equalTo: userInfoStack.bottomAnchor, constant: 12),
            buttonsStack.heightAnchor.constraint(equalToConstant: 44),
            buttonsStack.bottomAnchor.constraint(equalTo: userInfoContainer.bottomAnchor, constant: -24)
        ])
        // MARK: - 고객 지원
        let supportContainer = UIView()
        supportContainer.backgroundColor = .white
        supportContainer.layer.cornerRadius = 12
        supportContainer.layer.borderWidth = 1
        supportContainer.layer.borderColor = UIColor.systemGray4.cgColor
        supportContainer.translatesAutoresizingMaskIntoConstraints = false

        let supportContainerStack = UIStackView()
        supportContainerStack.axis = .vertical
        supportContainerStack.spacing = 16
        supportContainerStack.alignment = .fill
        supportContainerStack.translatesAutoresizingMaskIntoConstraints = false
        supportContainer.addSubview(supportContainerStack)

        NSLayoutConstraint.activate([
            supportContainerStack.topAnchor.constraint(equalTo: supportContainer.topAnchor, constant: 24),
            supportContainerStack.leadingAnchor.constraint(equalTo: supportContainer.leadingAnchor, constant: 20),
            supportContainerStack.trailingAnchor.constraint(equalTo: supportContainer.trailingAnchor, constant: -20),
            supportContainerStack.bottomAnchor.constraint(equalTo: supportContainer.bottomAnchor, constant: -24)
        ])

        let supportLabel = UILabel()
        supportLabel.text = "고객 지원"
        supportLabel.font = .boldSystemFont(ofSize: 16)
        supportContainerStack.addArrangedSubview(supportLabel)

        supportStack.axis = .vertical
        supportStack.spacing = 10
        supportStack.translatesAutoresizingMaskIntoConstraints = false

        termsButton.setTitle("이용 약관 >", for: .normal)
        privacyButton.setTitle("개인정보 처리방침 >", for: .normal)
        inquiryButton.setTitle("문의하기 >", for: .normal)

        supportStack.arrangedSubviews.forEach { $0.removeFromSuperview() }


        let termsIcon = UIImageView(image: UIImage(systemName: "doc.text"))
        termsIcon.tintColor = .systemGreen
        termsIcon.translatesAutoresizingMaskIntoConstraints = false
        termsIcon.widthAnchor.constraint(equalToConstant: 20).isActive = true
        termsIcon.heightAnchor.constraint(equalToConstant: 20).isActive = true
        termsButton.setTitleColor(.black, for: .normal)
        termsButton.contentHorizontalAlignment = .left
        let termsRow = UIStackView(arrangedSubviews: [termsIcon, termsButton])
        termsRow.axis = .horizontal
        termsRow.spacing = 8
        supportStack.addArrangedSubview(termsRow)


        let privacyIcon = UIImageView(image: UIImage(systemName: "lock.fill"))
        privacyIcon.tintColor = .systemGreen
        privacyIcon.translatesAutoresizingMaskIntoConstraints = false
        privacyIcon.widthAnchor.constraint(equalToConstant: 20).isActive = true
        privacyIcon.heightAnchor.constraint(equalToConstant: 20).isActive = true
        privacyButton.setTitleColor(.black, for: .normal)
        privacyButton.contentHorizontalAlignment = .left
        let privacyRow = UIStackView(arrangedSubviews: [privacyIcon, privacyButton])
        privacyRow.axis = .horizontal
        privacyRow.spacing = 8
        supportStack.addArrangedSubview(privacyRow)


        let inquiryIcon = UIImageView(image: UIImage(systemName: "message"))
        inquiryIcon.tintColor = .systemGreen
        inquiryIcon.translatesAutoresizingMaskIntoConstraints = false
        inquiryIcon.widthAnchor.constraint(equalToConstant: 20).isActive = true
        inquiryIcon.heightAnchor.constraint(equalToConstant: 20).isActive = true
        inquiryButton.setTitleColor(.black, for: .normal)
        inquiryButton.contentHorizontalAlignment = .left
        let inquiryRow = UIStackView(arrangedSubviews: [inquiryIcon, inquiryButton])
        inquiryRow.axis = .horizontal
        inquiryRow.spacing = 8
        supportStack.addArrangedSubview(inquiryRow)

        supportContainerStack.addArrangedSubview(supportStack)

        userViewStack.addArrangedSubview(userInfoContainer)
        userViewStack.addArrangedSubview(supportContainer)


        userViewStack.addArrangedSubview(logoutButton)
    }

    // 로그인 유무에 따른 뷰 전환
    func configureView(isLoggedIn: Bool) {
        userViewStack.isHidden = false
    }
}
