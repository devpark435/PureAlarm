//
//  AlarmDetail.swift
//  PureAlarm
//
//  Created by 박현렬 on 2/26/25.
//

import UIKit
import SnapKit
import Then

final class AlarmDetailViewController: UIViewController {
    
    // MARK: - Properties
    private var isEditMode: Bool = false
    private var selectedDays: [WeekDay] = []
    private var selectedColor: UIColor = UIColor(red: 0.4, green: 0.6, blue: 1.0, alpha: 1.0)
    
    // MARK: - UI Components
    private let gradientBackgroundView = GradientView(
        colors: [
            UIColor(red: 0.11, green: 0.11, blue: 0.18, alpha: 1.0),
            UIColor(red: 0.05, green: 0.05, blue: 0.1, alpha: 1.0)
        ]
    )
    
    private let closeButton = UIButton().then {
        $0.setImage(UIImage(systemName: "xmark"), for: .normal)
        $0.tintColor = .white
        $0.backgroundColor = UIColor(white: 0.2, alpha: 1.0)
        $0.layer.cornerRadius = 20
    }
    
    private let titleLabel = UILabel().then {
        $0.text = "알람 설정"
        $0.textColor = .white
        $0.font = .systemFont(ofSize: 24, weight: .bold)
    }
    
    private let saveButton = UIButton().then {
        $0.setTitle("저장", for: .normal)
        $0.setTitleColor(.white, for: .normal)
        $0.backgroundColor = UIColor(red: 0.4, green: 0.6, blue: 1.0, alpha: 1.0)
        $0.layer.cornerRadius = 12
    }
    
    private let timeContainerView = UIView().then {
        $0.backgroundColor = UIColor(white: 0.15, alpha: 1.0)
        $0.layer.cornerRadius = 16
    }
    
    private lazy var datePicker = UIDatePicker().then {
        $0.datePickerMode = .time
        $0.preferredDatePickerStyle = .wheels
        $0.setValue(UIColor.white, forKey: "textColor")
        $0.backgroundColor = .clear
    }
    
    private let optionsContainerView = UIView().then {
        $0.backgroundColor = UIColor(white: 0.15, alpha: 1.0)
        $0.layer.cornerRadius = 16
    }
    
    private let labelTextField = CustomTextField().then {
        $0.placeholder = "알람 제목"
        $0.textColor = .white
    }
    
    private let daysContainerView = UIView().then {
        $0.backgroundColor = .clear
    }
    
    private let daysLabel = UILabel().then {
        $0.text = "반복"
        $0.textColor = UIColor(white: 0.7, alpha: 1.0)
        $0.font = .systemFont(ofSize: 14)
    }
    
    private lazy var dayButtons: [UIButton] = WeekDay.allCases.map { day in
        let button = UIButton()
        button.setTitle(day.shortName, for: .normal)
        button.setTitleColor(UIColor(white: 0.7, alpha: 1.0), for: .normal)
        button.setTitleColor(.white, for: .selected)
        button.backgroundColor = UIColor(white: 0.2, alpha: 1.0)
        button.layer.cornerRadius = 15
        button.tag = day.rawValue
        button.addTarget(self, action: #selector(dayButtonTapped(_:)), for: .touchUpInside)
        return button
    }
    
    private let colorsContainerView = UIView().then {
        $0.backgroundColor = .clear
    }
    
    private let colorLabel = UILabel().then {
        $0.text = "색상"
        $0.textColor = UIColor(white: 0.7, alpha: 1.0)
        $0.font = .systemFont(ofSize: 14)
    }
    
    private lazy var colorButtons: [UIButton] = [
        UIColor(red: 0.4, green: 0.6, blue: 1.0, alpha: 1.0),
        UIColor(red: 0.6, green: 0.2, blue: 0.8, alpha: 1.0),
        UIColor(red: 1.0, green: 0.5, blue: 0.3, alpha: 1.0),
        UIColor(red: 0.4, green: 0.8, blue: 0.4, alpha: 1.0),
        UIColor(red: 0.8, green: 0.3, blue: 0.4, alpha: 1.0)
    ].enumerated().map { (index, color) in
        let button = UIButton()
        button.backgroundColor = color
        button.layer.cornerRadius = 15
        button.tag = index
        button.addTarget(self, action: #selector(colorButtonTapped(_:)), for: .touchUpInside)
        
        // 첫 번째 색상이 기본 선택
        if index == 0 {
            button.layer.borderWidth = 2
            button.layer.borderColor = UIColor.white.cgColor
        }
        
        return button
    }
    
    private let deleteButton = UIButton().then {
        $0.setTitle("알람 삭제", for: .normal)
        $0.setTitleColor(UIColor(red: 0.8, green: 0.2, blue: 0.2, alpha: 1.0), for: .normal)
        $0.backgroundColor = UIColor(white: 0.15, alpha: 1.0)
        $0.layer.cornerRadius = 12
        $0.addTarget(AlarmDetailViewController.self, action: #selector(deleteButtonTapped), for: .touchUpInside)
    }
    
    // MARK: - Lifecycle
    init(isEditMode: Bool = false) {
        self.isEditMode = isEditMode
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupButtonActions()
        configureUI()
        setupGestures()
    }
    
    // MARK: - Set Button Method
    private func setupButtonActions() {
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        saveButton.addTarget(self, action: #selector(saveButtonTapped), for: .touchUpInside)
    }
    
    // MARK: - UI Configuration
    private func configureUI() {
        view.addSubview(gradientBackgroundView)
        gradientBackgroundView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        view.addSubviews(
            closeButton, titleLabel, saveButton,
            timeContainerView, optionsContainerView
        )
        
        closeButton.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(20)
            $0.leading.equalToSuperview().offset(20)
            $0.size.equalTo(40)
        }
        
        titleLabel.snp.makeConstraints {
            $0.centerY.equalTo(closeButton)
            $0.centerX.equalToSuperview()
        }
        
        saveButton.snp.makeConstraints {
            $0.centerY.equalTo(closeButton)
            $0.trailing.equalToSuperview().offset(-20)
            $0.width.equalTo(70)
            $0.height.equalTo(40)
        }
        
        timeContainerView.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(30)
            $0.leading.equalToSuperview().offset(20)
            $0.trailing.equalToSuperview().offset(-20)
            $0.height.equalTo(200)
        }
        
        timeContainerView.addSubview(datePicker)
        datePicker.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.leading.trailing.equalToSuperview().inset(10)
            $0.height.equalTo(180)
        }
        
        optionsContainerView.snp.makeConstraints {
            $0.top.equalTo(timeContainerView.snp.bottom).offset(20)
            $0.leading.equalToSuperview().offset(20)
            $0.trailing.equalToSuperview().offset(-20)
            $0.bottom.lessThanOrEqualTo(view.safeAreaLayoutGuide.snp.bottom).offset(-20)
        }
        
        optionsContainerView.addSubviews(
            labelTextField, daysContainerView, colorsContainerView
        )
        
        labelTextField.snp.makeConstraints {
            $0.top.equalToSuperview().offset(20)
            $0.leading.equalToSuperview().offset(20)
            $0.trailing.equalToSuperview().offset(-20)
            $0.height.equalTo(50)
        }
        
        daysContainerView.snp.makeConstraints {
            $0.top.equalTo(labelTextField.snp.bottom).offset(20)
            $0.leading.equalToSuperview().offset(20)
            $0.trailing.equalToSuperview().offset(-20)
            $0.height.equalTo(60)
        }
        
        daysContainerView.addSubview(daysLabel)
        daysLabel.snp.makeConstraints {
            $0.leading.top.equalToSuperview()
        }
        
        let daysStackView = UIStackView(arrangedSubviews: dayButtons)
        daysStackView.axis = .horizontal
        daysStackView.spacing = 8
        daysStackView.distribution = .fillEqually
        
        daysContainerView.addSubview(daysStackView)
        daysStackView.snp.makeConstraints {
            $0.top.equalTo(daysLabel.snp.bottom).offset(10)
            $0.leading.trailing.bottom.equalToSuperview()
        }
        
        dayButtons.forEach { button in
            button.snp.makeConstraints {
                $0.height.equalTo(30)
            }
        }
        
        colorsContainerView.snp.makeConstraints {
            $0.top.equalTo(daysContainerView.snp.bottom).offset(20)
            $0.leading.equalToSuperview().offset(20)
            $0.trailing.equalToSuperview().offset(-20)
            $0.height.equalTo(60)
            $0.bottom.equalToSuperview().offset(-20)
        }
        
        colorsContainerView.addSubview(colorLabel)
        colorLabel.snp.makeConstraints {
            $0.leading.top.equalToSuperview()
        }
        
        let colorsStackView = UIStackView(arrangedSubviews: colorButtons)
        colorsStackView.axis = .horizontal
        colorsStackView.spacing = 16
        colorsStackView.distribution = .fillEqually
        
        colorsContainerView.addSubview(colorsStackView)
        colorsStackView.snp.makeConstraints {
            $0.top.equalTo(colorLabel.snp.bottom).offset(10)
            $0.leading.trailing.bottom.equalToSuperview().priority(.high)
        }
        
        colorButtons.forEach { button in
            button.snp.makeConstraints {
                $0.size.equalTo(30)
            }
        }
        
        // 삭제 버튼 (편집 모드에서만 표시)
        if isEditMode {
            view.addSubview(deleteButton)
            deleteButton.snp.makeConstraints {
                $0.centerX.equalToSuperview()
                $0.top.equalTo(optionsContainerView.snp.bottom).offset(30)
                $0.width.equalTo(140)
                $0.height.equalTo(44)
                $0.bottom.lessThanOrEqualTo(view.safeAreaLayoutGuide.snp.bottom).offset(-20)
            }
        }
    }
    
    private func setupGestures() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
    }
    
    // MARK: - Actions
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @objc private func closeButtonTapped() {
        dismiss(animated: true)
    }
    
    @objc private func saveButtonTapped() {
        // 알람 저장 로직
        print("알람 저장됨")
        dismiss(animated: true)
    }
    
    @objc private func deleteButtonTapped() {
        let alertController = UIAlertController(
            title: "알람 삭제",
            message: "이 알람을 삭제하시겠습니까?",
            preferredStyle: .alert
        )
        
        let cancelAction = UIAlertAction(title: "취소", style: .cancel)
        let deleteAction = UIAlertAction(title: "삭제", style: .destructive) { [weak self] _ in
            print("알람 삭제됨")
            self?.dismiss(animated: true)
        }
        
        alertController.addAction(cancelAction)
        alertController.addAction(deleteAction)
        present(alertController, animated: true)
    }
    
    @objc private func dayButtonTapped(_ sender: UIButton) {
        guard let day = WeekDay(rawValue: sender.tag) else { return }
        
        if let index = selectedDays.firstIndex(of: day) {
            selectedDays.remove(at: index)
            sender.backgroundColor = UIColor(white: 0.2, alpha: 1.0)
            sender.layer.borderWidth = 0
        } else {
            selectedDays.append(day)
            sender.backgroundColor = selectedColor.withAlphaComponent(0.3)
            sender.layer.borderWidth = 1
            sender.layer.borderColor = selectedColor.cgColor
        }
    }
    
    @objc private func colorButtonTapped(_ sender: UIButton) {
        // 이전 선택 상태 초기화
        colorButtons.forEach { button in
            button.layer.borderWidth = 0
        }
        
        // 현재 선택 상태 설정
        sender.layer.borderWidth = 2
        sender.layer.borderColor = UIColor.white.cgColor
        
        // 선택된 색상 저장
        guard sender.tag < colorButtons.count else { return }
        selectedColor = colorButtons[sender.tag].backgroundColor ?? .orange
        
        // 저장 버튼 색상 업데이트
        saveButton.backgroundColor = selectedColor
        
        // 선택된 요일 버튼들의 색상 업데이트
        updateDayButtonColors()
    }
    
    private func updateDayButtonColors() {
        for day in WeekDay.allCases {
            guard let button = dayButtons.first(where: { $0.tag == day.rawValue }) else { continue }
            
            if selectedDays.contains(day) {
                button.backgroundColor = selectedColor.withAlphaComponent(0.3)
                button.layer.borderWidth = 1
                button.layer.borderColor = selectedColor.cgColor
            }
        }
    }
}
