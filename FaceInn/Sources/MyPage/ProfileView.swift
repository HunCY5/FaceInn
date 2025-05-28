//
//  ProfileView.swift
//  FaceInn
//
//  Created by CHOI on 5/20/25.
//

import UIKit

final class ProfileView: UIView {
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
    let faceIDCard = UIView()
    let faceIDLabel = UILabel()
    let faceIDSubLabel = UILabel()
    let faceIDRegisterButton = UIButton(type: .system)
    let supportStack = UIStackView()
    let termsButton = UIButton(type: .system)
    let privacyButton = UIButton(type: .system)
    let inquiryButton = UIButton(type: .system)

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

        setupGuestView()
        setupUserView()

        contentStack.addArrangedSubview(guestViewStack)
        contentStack.addArrangedSubview(userViewStack)
    }

    // MARK: - Guest View: 구성요소 및 로그인 전 화면 UI 설정
    private func setupGuestView() {
        guestViewStack.axis = .vertical
        guestViewStack.spacing = 24
        guestViewStack.alignment = .fill
        guestViewStack.translatesAutoresizingMaskIntoConstraints = false

        // 로그인 안내 타이틀
        let guestContainer = UIView()
        guestContainer.backgroundColor = .white
        guestContainer.layer.cornerRadius = 12
        guestContainer.layer.borderWidth = 1
        guestContainer.layer.borderColor = UIColor.systemGray4.cgColor
        guestContainer.translatesAutoresizingMaskIntoConstraints = false

        let guestStack = UIStackView()
        guestStack.axis = .vertical
        guestStack.spacing = 16
        guestStack.alignment = .center
        guestStack.translatesAutoresizingMaskIntoConstraints = false
        guestContainer.addSubview(guestStack)

        NSLayoutConstraint.activate([
            guestStack.topAnchor.constraint(equalTo: guestContainer.topAnchor, constant: 24),
            guestStack.leadingAnchor.constraint(equalTo: guestContainer.leadingAnchor, constant: 20),
            guestStack.trailingAnchor.constraint(equalTo: guestContainer.trailingAnchor, constant: -20),
            guestStack.bottomAnchor.constraint(equalTo: guestContainer.bottomAnchor, constant: -24)
        ])

        // 로그인 안내 타이틀
        let title = UILabel()
        title.text = "로그인이 필요합니다"
        title.font = .boldSystemFont(ofSize: 22)
        title.textAlignment = .center

        // 로그인 아이콘
        let icon = UIImageView(image: UIImage(systemName: "person.circle"))
        icon.tintColor = .gray
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.contentMode = .scaleAspectFit
        icon.heightAnchor.constraint(equalToConstant: 60).isActive = true

        // 로그인 설명
        let explain = UILabel()
        explain.text = "로그인하여 예약 내역 및 개인 정보를 관리하세요."
        explain.font = .systemFont(ofSize: 14)
        explain.textColor = .gray
        explain.numberOfLines = 0
        explain.textAlignment = .center

        // 로그인 버튼
        loginButton = UIButton(type: .system)
        loginButton.setTitle("로그인", for: .normal)
        loginButton.setTitleColor(.white, for: .normal)
        loginButton.backgroundColor = UIColor(red: 0x2f/255, green: 0xaf/255, blue: 0x53/255, alpha: 1)
        loginButton.layer.cornerRadius = 6
        loginButton.titleLabel?.font = .systemFont(ofSize: 15, weight: .medium)
        loginButton.contentEdgeInsets = UIEdgeInsets(top: 10, left: 30, bottom: 10, right: 30)
        loginButton.translatesAutoresizingMaskIntoConstraints = false

        [title, icon, explain, loginButton].forEach { view in
            guestStack.addArrangedSubview(view)
            if let label = view as? UILabel {
                label.textAlignment = .center
            }
        }


        let faceIDContainer = UIView()
        faceIDContainer.backgroundColor = .white
        faceIDContainer.layer.cornerRadius = 12
        faceIDContainer.layer.borderWidth = 1
        faceIDContainer.layer.borderColor = UIColor.systemGray4.cgColor
        faceIDContainer.translatesAutoresizingMaskIntoConstraints = false

        let faceIDStack = UIStackView()
        faceIDStack.axis = .vertical
        faceIDStack.alignment = .center
        faceIDStack.spacing = 12
        faceIDStack.translatesAutoresizingMaskIntoConstraints = false
        faceIDContainer.addSubview(faceIDStack)

        NSLayoutConstraint.activate([
            faceIDStack.topAnchor.constraint(equalTo: faceIDContainer.topAnchor, constant: 24),
            faceIDStack.leadingAnchor.constraint(equalTo: faceIDContainer.leadingAnchor, constant: 20),
            faceIDStack.trailingAnchor.constraint(equalTo: faceIDContainer.trailingAnchor, constant: -20),
            faceIDStack.bottomAnchor.constraint(equalTo: faceIDContainer.bottomAnchor, constant: -24)
        ])

        // Face ID 아이콘
        let faceIDIcon = UIImageView(image: UIImage(systemName: "faceid"))
        faceIDIcon.tintColor = UIColor(red: 0x2f/255, green: 0xaf/255, blue: 0x53/255, alpha: 1)
        faceIDIcon.translatesAutoresizingMaskIntoConstraints = false
        faceIDIcon.widthAnchor.constraint(equalToConstant: 48).isActive = true
        faceIDIcon.heightAnchor.constraint(equalToConstant: 48).isActive = true

        // Face ID 라벨
        faceIDLabel.text = "얼굴 정보"
        faceIDLabel.font = .boldSystemFont(ofSize: 17)

        // Face ID 서브라벨
        faceIDSubLabel.text = "얼굴 정보를 통해 빠르고 편리하게 체크인할 수 있습니다."
        faceIDSubLabel.font = .systemFont(ofSize: 13)
        faceIDSubLabel.textColor = .gray
        faceIDSubLabel.textAlignment = .center
        faceIDSubLabel.numberOfLines = 0

        let bottomText = UILabel()
        bottomText.text = "로그인 후 얼굴 정보를 등록하면 빠른 체크인이 가능합니다."
        bottomText.font = .systemFont(ofSize: 13)
        bottomText.textColor = .gray
        bottomText.textAlignment = .center
        bottomText.numberOfLines = 0

        // Face ID 로그인 버튼
        faceIDLoginButton = UIButton(type: .system)
        faceIDLoginButton.setTitle("로그인하여 사용하기", for: .normal)
        faceIDLoginButton.setTitleColor(.white, for: .normal)
        faceIDLoginButton.backgroundColor = UIColor(red: 0x2f/255, green: 0xaf/255, blue: 0x53/255, alpha: 1)
        faceIDLoginButton.layer.cornerRadius = 6
        faceIDLoginButton.titleLabel?.font = .systemFont(ofSize: 15, weight: .medium)
        faceIDLoginButton.contentEdgeInsets = UIEdgeInsets(top: 10, left: 20, bottom: 10, right: 20)
        faceIDLoginButton.translatesAutoresizingMaskIntoConstraints = false


        faceIDStack.addArrangedSubview(faceIDIcon)
        faceIDStack.addArrangedSubview(faceIDLabel)
        faceIDStack.addArrangedSubview(faceIDSubLabel)
        faceIDStack.addArrangedSubview(bottomText)
        faceIDStack.addArrangedSubview(faceIDLoginButton)

        guestViewStack.addArrangedSubview(guestContainer)
        guestViewStack.addArrangedSubview(faceIDContainer)

        // 고객 지원
        let supportStack = UIStackView()
        supportStack.axis = .vertical
        supportStack.spacing = 10
        supportStack.translatesAutoresizingMaskIntoConstraints = false
        
        let supportTitle = UILabel()
        supportTitle.text = "고객 지원"
        supportTitle.font = .boldSystemFont(ofSize: 16)

        let supportSubtitle = UILabel()
        supportSubtitle.text = "서비스 이용에 관한 정보를 확인하세요."
        supportSubtitle.font = .systemFont(ofSize: 13)
        supportSubtitle.textColor = .gray

        supportStack.addArrangedSubview(supportTitle)
        supportStack.addArrangedSubview(supportSubtitle)

        // 이용 약관
        let termsIcon = UIImageView(image: UIImage(systemName: "doc.text"))
        termsIcon.tintColor = .systemGreen
        termsIcon.widthAnchor.constraint(equalToConstant: 20).isActive = true
        termsIcon.heightAnchor.constraint(equalToConstant: 20).isActive = true

        let termsButton = UIButton(type: .system)
        termsButton.setTitle("이용 약관 >", for: .normal)
        termsButton.setTitleColor(.black, for: .normal)
        termsButton.contentHorizontalAlignment = .left

        let termsRow = UIStackView(arrangedSubviews: [termsIcon, termsButton])
        termsRow.axis = .horizontal
        termsRow.spacing = 8

        // 개인정보 처리방침
        let privacyIcon = UIImageView(image: UIImage(systemName: "lock.fill"))
        privacyIcon.tintColor = .systemGreen
        privacyIcon.widthAnchor.constraint(equalToConstant: 20).isActive = true
        privacyIcon.heightAnchor.constraint(equalToConstant: 20).isActive = true

        let privacyButton = UIButton(type: .system)
        privacyButton.setTitle("개인정보 처리방침 >", for: .normal)
        privacyButton.setTitleColor(.black, for: .normal)
        privacyButton.contentHorizontalAlignment = .left

        let privacyRow = UIStackView(arrangedSubviews: [privacyIcon, privacyButton])
        privacyRow.axis = .horizontal
        privacyRow.spacing = 8

        supportStack.addArrangedSubview(termsRow)
        supportStack.addArrangedSubview(privacyRow)

        guestViewStack.addArrangedSubview(supportStack)

        // 호스트 로그인 텍스트 버튼
        let hostLoginButton = UIButton(type: .system)
        hostLoginButton.setTitle("숙소 호스트이신가요? 로그인하기", for: .normal)
        hostLoginButton.setTitleColor(UIColor(hex: "#2faf53"), for: .normal)
        hostLoginButton.titleLabel?.font = .systemFont(ofSize: 14)
        hostLoginButton.contentHorizontalAlignment = .center
        hostLoginButton.translatesAutoresizingMaskIntoConstraints = false
        guestViewStack.addArrangedSubview(hostLoginButton)
        self.hostLoginButton = hostLoginButton
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

        NSLayoutConstraint.activate([
            editButton.leadingAnchor.constraint(equalTo: userInfoContainer.leadingAnchor, constant: 20),
            editButton.trailingAnchor.constraint(equalTo: userInfoContainer.trailingAnchor, constant: -20),
            editButton.topAnchor.constraint(equalTo: userInfoStack.bottomAnchor, constant: 12),
            editButton.heightAnchor.constraint(equalToConstant: 44),
            editButton.bottomAnchor.constraint(equalTo: userInfoContainer.bottomAnchor, constant: -24)
        ])

        // MARK: - Face ID 등록
        faceIDCard.backgroundColor = UIColor.systemGray6
        faceIDCard.layer.cornerRadius = 12
        faceIDCard.layer.borderWidth = 1
        faceIDCard.layer.borderColor = UIColor.systemGray4.cgColor
        faceIDCard.translatesAutoresizingMaskIntoConstraints = false

        let faceIDStack = UIStackView()
        faceIDStack.axis = .horizontal
        faceIDStack.alignment = .center
        faceIDStack.spacing = 12
        faceIDStack.translatesAutoresizingMaskIntoConstraints = false

        let faceIDIcon = UIImageView(image: UIImage(systemName: "faceid"))
        faceIDIcon.tintColor = UIColor(red: 0x2f/255, green: 0xaf/255, blue: 0x53/255, alpha: 1)
        faceIDIcon.translatesAutoresizingMaskIntoConstraints = false
        faceIDIcon.widthAnchor.constraint(equalToConstant: 40).isActive = true
        faceIDIcon.heightAnchor.constraint(equalToConstant: 40).isActive = true

        let faceIDTextStack = UIStackView()
        faceIDTextStack.axis = .vertical
        faceIDTextStack.spacing = 4
        faceIDTextStack.alignment = .leading

        faceIDLabel.text = "얼굴 정보 미등록"
        faceIDLabel.font = .boldSystemFont(ofSize: 14)

        faceIDSubLabel.text = "얼굴 정보를 등록하면 \n빠른 체크인이 가능합니다."
        faceIDSubLabel.font = .systemFont(ofSize: 13)
        faceIDSubLabel.textColor = .gray

        faceIDTextStack.addArrangedSubview(faceIDLabel)
        faceIDTextStack.addArrangedSubview(faceIDSubLabel)

        faceIDRegisterButton.setTitle("등록하기", for: .normal)
        faceIDRegisterButton.setTitleColor(.white, for: .normal)
        faceIDRegisterButton.backgroundColor = UIColor(red: 0x2f/255, green: 0xaf/255, blue: 0x53/255, alpha: 1)
        faceIDRegisterButton.layer.cornerRadius = 6
        faceIDRegisterButton.contentEdgeInsets = UIEdgeInsets(top: 6, left: 16, bottom: 6, right: 16)

        faceIDStack.addArrangedSubview(faceIDIcon)
        faceIDStack.addArrangedSubview(faceIDTextStack)
        faceIDStack.addArrangedSubview(faceIDRegisterButton)

        faceIDCard.addSubview(faceIDStack)
        faceIDStack.leadingAnchor.constraint(equalTo: faceIDCard.leadingAnchor, constant: 12).isActive = true
        faceIDStack.trailingAnchor.constraint(equalTo: faceIDCard.trailingAnchor, constant: -12).isActive = true
        faceIDStack.topAnchor.constraint(equalTo: faceIDCard.topAnchor, constant: 12).isActive = true
        faceIDStack.bottomAnchor.constraint(equalTo: faceIDCard.bottomAnchor, constant: -12).isActive = true

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
        userViewStack.addArrangedSubview(faceIDCard)
        userViewStack.addArrangedSubview(supportContainer)


        userViewStack.addArrangedSubview(logoutButton)
    }

    // 로그인 유무에 따른 뷰 전환
    func configureView(isLoggedIn: Bool) {
        guestViewStack.isHidden = isLoggedIn
        userViewStack.isHidden = !isLoggedIn
    }
}



extension UIColor {
    convenience init(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)

        let r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
        let g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
        let b = CGFloat(rgb & 0x0000FF) / 255.0

        self.init(red: r, green: g, blue: b, alpha: 1.0)
    }
}
