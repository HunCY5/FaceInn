//
//  RoomRegisterView.swift
//  FaceInn
//
//  Created by 신찬솔 on 5/31/25.
//


import UIKit

extension RoomRegisterView {
    func showLoading() {
        let loadingView = UIActivityIndicatorView(style: .large)
        loadingView.center = self.center
        loadingView.color = .gray
        loadingView.tag = 999 // 특정 태그로 구분
        loadingView.startAnimating()
        self.addSubview(loadingView)
        self.isUserInteractionEnabled = false
    }

    func hideLoading() {
        if let loadingView = self.viewWithTag(999) as? UIActivityIndicatorView {
            loadingView.stopAnimating()
            loadingView.removeFromSuperview()
        }
        self.isUserInteractionEnabled = true
    }
}

final class RoomRegisterView: UIView {

    private let loadingView: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.hidesWhenStopped = true
        indicator.backgroundColor = UIColor(white: 0, alpha: 0.4)
        indicator.layer.cornerRadius = 8
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()

    public var selectedImages: [UIImage] = []
    public var selectedAmenities: Set<String> = []

    public let photoCountLabel: UILabel = {
        let label = UILabel()
        label.text = "0 / 10"
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .darkGray
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    
    public var deleteImageHandler: ((Int) -> Void)?
    public var amenityButtonHandler: ((UIButton) -> Void)?

    public let scrollView = UIScrollView()
    public let contentView = UIView()

    public let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 400, height: 200)
        layout.minimumLineSpacing = 8
        layout.sectionInset = .init(top: 0, left: 16, bottom: 0, right: 16)
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = UIColor(white: 0.95, alpha: 1)
        collectionView.layer.cornerRadius = 8
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        return collectionView
    }()

    public let selectImageButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("사진 추가", for: .normal)
        button.setTitleColor(UIColor(red: 47/255, green: 175/255, blue: 83/255, alpha: 1.0), for: .normal)
        button.backgroundColor = .clear
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    public let nameLabel: UILabel = {
        let label = UILabel()
        label.text = "객실 이름"
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    public let nameTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "객실 이름을 입력하세요"
        tf.borderStyle = .roundedRect
        tf.font = .systemFont(ofSize: 14, weight: .medium)
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()

    public let addressLabel: UILabel = {
        let label = UILabel()
        label.text = "가격"
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    public let addressTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "가격을 입력하세요"
        tf.borderStyle = .roundedRect
        tf.keyboardType = .numberPad
        tf.font = .systemFont(ofSize: 14, weight: .medium)
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()

    public let descriptionLabel: UILabel = {
        let label = UILabel()
        label.text = "객실 설명"
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    public let descriptionTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "객실 설명을 입력하세요"
        tf.borderStyle = .roundedRect
        tf.font = .systemFont(ofSize: 14, weight: .medium)
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()

    public let capacityLabel: UILabel = {
        let label = UILabel()
        label.text = "최대 인원"
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    public let capacityTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "최대 인원을 입력하세요"
        tf.borderStyle = .roundedRect
        tf.keyboardType = .numberPad
        tf.font = .systemFont(ofSize: 14, weight: .medium)
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()

    public let checkInLabel: UILabel = {
        let label = UILabel()
        label.text = "체크인 시간"
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    public let checkInPicker: UIDatePicker = {
        let picker = UIDatePicker()
        picker.datePickerMode = .time
        picker.preferredDatePickerStyle = .wheels
        picker.locale = Locale(identifier: "ko_KR")
        let checkInDate = Calendar.current.date(bySettingHour: 15, minute: 0, second: 0, of: Date()) ?? Date()
        picker.date = checkInDate
        picker.translatesAutoresizingMaskIntoConstraints = false
        return picker
    }()

    public let checkOutLabel: UILabel = {
        let label = UILabel()
        label.text = "체크아웃 시간"
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    public let checkOutPicker: UIDatePicker = {
        let picker = UIDatePicker()
        picker.datePickerMode = .time
        picker.preferredDatePickerStyle = .wheels
        picker.locale = Locale(identifier: "ko_KR")
        let checkOutDate = Calendar.current.date(bySettingHour: 11, minute: 0, second: 0, of: Date()) ?? Date()
        picker.date = checkOutDate
        picker.translatesAutoresizingMaskIntoConstraints = false
        return picker
    }()

    public let amenitiesLabel: UILabel = {
        let label = UILabel()
        label.text = "편의시설"
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    public let amenitiesStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    public let registerButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("등록하기", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor(red: 47/255, green: 175/255, blue: 83/255, alpha: 1.0)
        button.layer.cornerRadius = 8
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    // MARK: - Initializer
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupConstraints()
        addDoneButtonOnKeyboard(for: nameTextField)
        addDoneButtonOnKeyboard(for: addressTextField)
        addDoneButtonOnKeyboard(for: descriptionTextField)
        setupKeyboardDismissGesture()

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func setupViews() {
        backgroundColor = .white

        // Enable vertical scrolling and proper content sizing
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.alwaysBounceVertical = true
        scrollView.showsVerticalScrollIndicator = true
        addSubview(scrollView)
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)

        let amenities = [
            "Wi-Fi", "에어컨", "난방", "엘리베이터", "무료 주차",
            "조식 제공", "레스토랑", "룸서비스",
            "세탁기", "건조기", "욕조", "헤어드라이어",
            "수영장", "피트니스",
            "반려동물 가능",
            "바다 전망", "테라스", "발코니"
        ]
        let buttonsPerRow = 3
        for rowIndex in 0 ..< ((amenities.count + buttonsPerRow - 1) / buttonsPerRow) {
            let rowStack = UIStackView()
            rowStack.axis = .horizontal
            rowStack.distribution = .fillEqually
            rowStack.spacing = 8
            rowStack.translatesAutoresizingMaskIntoConstraints = false

            for colIndex in 0..<buttonsPerRow {
                let index = rowIndex * buttonsPerRow + colIndex
                if index < amenities.count {
                    let button = UIButton(type: .system)
                    button.setTitle(amenities[index], for: .normal)
                    button.setTitleColor(.black, for: .normal)
                    button.backgroundColor = .white
                    button.layer.borderWidth = 1
                    button.layer.borderColor = UIColor.lightGray.cgColor
                    button.layer.cornerRadius = 8
                    button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
                    button.contentEdgeInsets = UIEdgeInsets(top: 6, left: 12, bottom: 6, right: 12)
                    button.translatesAutoresizingMaskIntoConstraints = false
                    button.heightAnchor.constraint(equalToConstant: 36).isActive = true
                    button.addTarget(self, action: #selector(toggleAmenity(_:)), for: .touchUpInside)
                    rowStack.addArrangedSubview(button)
                } else {
                    let spacer = UIView()
                    spacer.translatesAutoresizingMaskIntoConstraints = false
                    rowStack.addArrangedSubview(spacer)
                }
            }
            amenitiesStackView.addArrangedSubview(rowStack)
        }

        let fields: [UIView] = [
            collectionView,
            photoCountLabel,
            selectImageButton,
            nameLabel,
            nameTextField,
            addressLabel,
            addressTextField,
            capacityLabel,
            capacityTextField,
            checkInLabel,
            checkInPicker,
            checkOutLabel,
            checkOutPicker,
            descriptionLabel,
            descriptionTextField,
            amenitiesLabel,
            amenitiesStackView,
            registerButton
        ]

        fields.forEach { view in
            contentView.addSubview(view)
        }

        let logoutButton: UIButton = {
            let button = UIButton(type: .system)
            button.setTitle("로그아웃", for: .normal)
            button.setTitleColor(.systemRed, for: .normal)
            button.backgroundColor = .clear
            button.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
            button.translatesAutoresizingMaskIntoConstraints = false
            return button
        }()
        // Add loadingView
        addSubview(loadingView)
        NSLayoutConstraint.activate([
            loadingView.centerXAnchor.constraint(equalTo: centerXAnchor),
            loadingView.centerYAnchor.constraint(equalTo: centerYAnchor),
            loadingView.widthAnchor.constraint(equalTo: widthAnchor),
            loadingView.heightAnchor.constraint(equalTo: heightAnchor)
        ])
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            // contentView.heightAnchor.constraint(greaterThanOrEqualTo: scrollView.heightAnchor), // Removed for dynamic sizing
            contentView.bottomAnchor.constraint(equalTo: registerButton.bottomAnchor, constant: 24),

            collectionView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            collectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            collectionView.heightAnchor.constraint(equalToConstant: 200),

            photoCountLabel.topAnchor.constraint(equalTo: collectionView.bottomAnchor, constant: 4),
            photoCountLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            selectImageButton.topAnchor.constraint(equalTo: photoCountLabel.bottomAnchor, constant: 4),
            selectImageButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            selectImageButton.heightAnchor.constraint(equalToConstant: 40),
            selectImageButton.widthAnchor.constraint(equalToConstant: 120),

            nameLabel.topAnchor.constraint(equalTo: selectImageButton.bottomAnchor, constant: 16),
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),

            nameTextField.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            nameTextField.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            nameTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            nameTextField.heightAnchor.constraint(equalToConstant: 40),

            addressLabel.topAnchor.constraint(equalTo: nameTextField.bottomAnchor, constant: 16),
            addressLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),

            addressTextField.topAnchor.constraint(equalTo: addressLabel.bottomAnchor, constant: 4),
            addressTextField.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            addressTextField.trailingAnchor.constraint(equalTo: nameTextField.trailingAnchor),
            addressTextField.heightAnchor.constraint(equalToConstant: 40),

            capacityLabel.topAnchor.constraint(equalTo: addressTextField.bottomAnchor, constant: 16),
            capacityLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),

            capacityTextField.topAnchor.constraint(equalTo: capacityLabel.bottomAnchor, constant: 4),
            capacityTextField.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            capacityTextField.trailingAnchor.constraint(equalTo: nameTextField.trailingAnchor),
            capacityTextField.heightAnchor.constraint(equalToConstant: 40),

            checkInLabel.topAnchor.constraint(equalTo: capacityTextField.bottomAnchor, constant: 16),
            checkInLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),

            checkInPicker.topAnchor.constraint(equalTo: checkInLabel.bottomAnchor, constant: 4),
            checkInPicker.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            checkInPicker.trailingAnchor.constraint(equalTo: nameTextField.trailingAnchor),

            checkOutLabel.topAnchor.constraint(equalTo: checkInPicker.bottomAnchor, constant: 16),
            checkOutLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),

            checkOutPicker.topAnchor.constraint(equalTo: checkOutLabel.bottomAnchor, constant: 4),
            checkOutPicker.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            checkOutPicker.trailingAnchor.constraint(equalTo: nameTextField.trailingAnchor),

            descriptionLabel.topAnchor.constraint(equalTo: checkOutPicker.bottomAnchor, constant: 16),
            descriptionLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),

            descriptionTextField.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 4),
            descriptionTextField.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            descriptionTextField.trailingAnchor.constraint(equalTo: nameTextField.trailingAnchor),
            descriptionTextField.heightAnchor.constraint(equalToConstant: 40),

            amenitiesLabel.topAnchor.constraint(equalTo: descriptionTextField.bottomAnchor, constant: 16),
            amenitiesLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),

            amenitiesStackView.topAnchor.constraint(equalTo: amenitiesLabel.bottomAnchor, constant: 8),
            amenitiesStackView.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            amenitiesStackView.trailingAnchor.constraint(equalTo: nameTextField.trailingAnchor),

            registerButton.topAnchor.constraint(equalTo: amenitiesStackView.bottomAnchor, constant: 24),
            registerButton.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            registerButton.trailingAnchor.constraint(equalTo: nameTextField.trailingAnchor),
            registerButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }

    @objc func toggleAmenity(_ sender: UIButton) {
        if sender.backgroundColor == UIColor.white {
            sender.backgroundColor = UIColor(red: 47/255, green: 175/255, blue: 83/255, alpha: 1)
            sender.setTitleColor(.white, for: .normal)
            sender.layer.borderColor = UIColor.clear.cgColor
        } else {
            sender.backgroundColor = .white
            sender.setTitleColor(.black, for: .normal)
            sender.layer.borderColor = UIColor.lightGray.cgColor
        }
        // Update selectedAmenities based on button title and selection state
        if let title = sender.title(for: .normal) {
            if selectedAmenities.contains(title) {
                selectedAmenities.remove(title)
            } else {
                selectedAmenities.insert(title)
            }
        }
        amenityButtonHandler?(sender)
    }

    @objc private func keyboardWillShow(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let keyboardFrameValue = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue,
              let animationDuration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double,
              let animationCurveRawValue = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt else { return }
        let keyboardFrame = keyboardFrameValue.cgRectValue
        let keyboardHeight = keyboardFrame.height

        let animationOptions = UIView.AnimationOptions(rawValue: animationCurveRawValue << 16)

        UIView.animate(withDuration: animationDuration, delay: 0, options: animationOptions, animations: {
            self.scrollView.contentInset.bottom = keyboardHeight
            self.scrollView.scrollIndicatorInsets.bottom = keyboardHeight
        }, completion: nil)
    }

    @objc private func keyboardWillHide(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let animationDuration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double,
              let animationCurveRawValue = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt else { return }

        let animationOptions = UIView.AnimationOptions(rawValue: animationCurveRawValue << 16)

        UIView.animate(withDuration: animationDuration, delay: 0, options: animationOptions, animations: {
            self.scrollView.contentInset.bottom = 0
            self.scrollView.scrollIndicatorInsets.bottom = 0
        }, completion: nil)
    }

    private func addDoneButtonOnKeyboard(for textField: UITextField) {
        let toolbar: UIToolbar = UIToolbar()
        toolbar.sizeToFit()

        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let done: UIBarButtonItem = UIBarButtonItem(title: "완료", style: .done, target: self, action: #selector(doneButtonAction))

        toolbar.items = [flexSpace, done]
        textField.inputAccessoryView = toolbar
    }

    @objc private func doneButtonAction() {
        endEditing(true)
    }

    private func setupKeyboardDismissGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        addGestureRecognizer(tapGesture)
    }

    @objc private func dismissKeyboard() {
        endEditing(true)
    }
    public func addImages(_ images: [UIImage]) {
        let newImages = images.filter { newImage in
            !selectedImages.contains(where: { existing in
                existing.pngData() == newImage.pngData()
            })
        }
        selectedImages.append(contentsOf: newImages)
    }
    
}
