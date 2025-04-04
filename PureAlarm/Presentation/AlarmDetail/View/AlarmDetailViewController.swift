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
    private let viewModel: AlarmDetailViewModel
    private var selectedDays: [WeekDay] = []
    private var selectedColor: UIColor = UIColor(red: 0.4, green: 0.6, blue: 1.0, alpha: 1.0)
    private var selectedRepeatInterval: Int = 0
    
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
        
        return button
    }
    
    private let deleteButton = UIButton().then {
        $0.setTitle("알람 삭제", for: .normal)
        $0.setTitleColor(UIColor(red: 0.8, green: 0.2, blue: 0.2, alpha: 1.0), for: .normal)
        $0.backgroundColor = UIColor(white: 0.15, alpha: 1.0)
        $0.layer.cornerRadius = 12
    }
    
    private let repeatIntervalContainerView = UIView().then {
        $0.backgroundColor = .clear
    }
    
    private let repeatIntervalLabel = UILabel().then {
        $0.text = "알람 반복 간격"
        $0.textColor = UIColor(white: 0.7, alpha: 1.0)
        $0.font = .systemFont(ofSize: 14)
    }
    
    private lazy var repeatIntervalSegmentedControl = UISegmentedControl(items: ["없음", "1분", "3분", "5분", "10분"]).then {
        $0.selectedSegmentIndex = 0
        $0.backgroundColor = UIColor(white: 0.2, alpha: 1.0)
        
        // 세그먼트 컨트롤 스타일 설정
        $0.setTitleTextAttributes([.foregroundColor: UIColor(white: 0.7, alpha: 1.0)], for: .normal)
        $0.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
        
        if #available(iOS 13.0, *) {
            $0.selectedSegmentTintColor = selectedColor
        } else {
            $0.tintColor = selectedColor
        }
    }
    
    // MARK: - Lifecycle
    init(viewModel: AlarmDetailViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        setupGestures()
        setupButtonActions()
        updateUIFromViewModel()
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
            labelTextField, daysContainerView, repeatIntervalContainerView, colorsContainerView
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
        
        repeatIntervalContainerView.snp.makeConstraints {
            $0.top.equalTo(daysContainerView.snp.bottom).offset(20)
            $0.leading.equalToSuperview().offset(20)
            $0.trailing.equalToSuperview().offset(-20)
            $0.height.equalTo(60)
        }
        
        repeatIntervalContainerView.addSubview(repeatIntervalLabel)
        repeatIntervalLabel.snp.makeConstraints {
            $0.leading.top.equalToSuperview()
        }
        
        repeatIntervalContainerView.addSubview(repeatIntervalSegmentedControl)
        repeatIntervalSegmentedControl.snp.makeConstraints {
            $0.top.equalTo(repeatIntervalLabel.snp.bottom).offset(10)
            $0.leading.trailing.bottom.equalToSuperview()
            $0.height.equalTo(30)
        }
        
        colorsContainerView.snp.makeConstraints {
            $0.top.equalTo(repeatIntervalContainerView.snp.bottom).offset(20)
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
            $0.leading.trailing.bottom.equalToSuperview()
        }
        
        colorButtons.forEach { button in
            button.snp.makeConstraints {
                $0.size.equalTo(30).priority(.high)
            }
        }
        
        // 삭제 버튼 (편집 모드에서만 표시)
        if viewModel.isEditMode {
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
    
    private func setupButtonActions() {
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        saveButton.addTarget(self, action: #selector(saveButtonTapped), for: .touchUpInside)
        deleteButton.addTarget(self, action: #selector(deleteButtonTapped), for: .touchUpInside)
        repeatIntervalSegmentedControl.addTarget(self, action: #selector(repeatIntervalChanged(_:)), for: .valueChanged)
        
        // 요일 버튼 액션
        for button in dayButtons {
            button.addTarget(self, action: #selector(dayButtonTapped(_:)), for: .touchUpInside)
        }
        
        // 색상 버튼 액션
        for button in colorButtons {
            button.addTarget(self, action: #selector(colorButtonTapped(_:)), for: .touchUpInside)
        }
    }
    
    private func updateUIFromViewModel() {
        // 뷰모델의 데이터로 UI 업데이트
        titleLabel.text = viewModel.isEditMode ? "알람 편집" : "알람 추가"
        labelTextField.text = viewModel.title
        
        // 알람 시간을 DatePicker에 설정할 때 현지 시간 고려
        datePicker.date = viewModel.time
        
        selectedDays = viewModel.selectedDays
        selectedColor = viewModel.selectedColor
        
        // 타이틀 업데이트
        titleLabel.text = viewModel.isEditMode ? "알람 편집" : "알람 추가"
        
        // 저장 버튼 색상 업데이트
        saveButton.backgroundColor = selectedColor
        
        // 반복 간격 업데이트
        selectedRepeatInterval = viewModel.repeatInterval
        switch selectedRepeatInterval {
        case 1: repeatIntervalSegmentedControl.selectedSegmentIndex = 1
        case 3: repeatIntervalSegmentedControl.selectedSegmentIndex = 2
        case 5: repeatIntervalSegmentedControl.selectedSegmentIndex = 3
        case 10: repeatIntervalSegmentedControl.selectedSegmentIndex = 4
        default: repeatIntervalSegmentedControl.selectedSegmentIndex = 0
        }
        
        // 요일 버튼 상태 업데이트
        updateDayButtons()
        
        // 색상 버튼 상태 업데이트
        updateColorButtons()
    }
    
    private func updateDayButtons() {
        for button in dayButtons {
            guard let day = WeekDay(rawValue: button.tag) else { continue }
            let isSelected = selectedDays.contains(day)
            
            // 선택 상태 업데이트
            if isSelected {
                button.backgroundColor = selectedColor.withAlphaComponent(0.3)
                button.layer.borderWidth = 1
                button.layer.borderColor = selectedColor.cgColor
            } else {
                button.backgroundColor = UIColor(white: 0.2, alpha: 1.0)
                button.layer.borderWidth = 0
            }
        }
    }
    
    private func updateColorButtons() {
        for (index, button) in colorButtons.enumerated() {
            if index < colorButtons.count && button.backgroundColor == selectedColor {
                button.layer.borderWidth = 2
                button.layer.borderColor = UIColor.white.cgColor
            } else {
                button.layer.borderWidth = 0
            }
        }
    }
    
    // MARK: - Actions
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @objc private func closeButtonTapped() {
        dismiss(animated: true)
    }
    
    @objc private func saveButtonTapped() {
        // DatePicker에서 선택한 시간을 현지 시간으로 변환
        let localTime = Date.convertPickerDateToLocalTime(datePicker.date)
        
        // 알람 데이터 업데이트
        viewModel.updateTitle(labelTextField.text ?? "알람")
        viewModel.updateTime(localTime) // 수정된 부분
        viewModel.updateDays(selectedDays)
        viewModel.updateRepeatInterval(selectedRepeatInterval)
        viewModel.updateColor(selectedColor)
        
        // 저장 전 로그 출력 (확인용)
        print("저장 시간 (현지): \(localTime.getLocalFormattedTime())")
        print("저장 시간 (시, 분): \(localTime.localHour)시 \(localTime.localMinute)분")
        
        // 알람 저장
        viewModel.saveAlarm()
        
        // 화면 닫기
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
            self?.viewModel.deleteAlarm()
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
        
        // 뷰모델 업데이트
        viewModel.updateDays(selectedDays)
    }
    
    @objc private func repeatIntervalChanged(_ sender: UISegmentedControl) {
        // 선택된 인덱스에 따라 반복 간격 설정
        switch sender.selectedSegmentIndex {
        case 0: selectedRepeatInterval = 0  // 반복 없음
        case 1: selectedRepeatInterval = 1  // 1분
        case 2: selectedRepeatInterval = 3  // 3분
        case 3: selectedRepeatInterval = 5 // 5분
        case 4: selectedRepeatInterval = 10 // 10분
        default: selectedRepeatInterval = 0
        }
        
        // 세그먼트 컨트롤 색상 업데이트
        if #available(iOS 13.0, *) {
            repeatIntervalSegmentedControl.selectedSegmentTintColor = selectedColor
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
        updateDayButtons()
        
        // 선택된 반복 세그먼트 색상 업데이트
        if #available(iOS 13.0, *) {
            repeatIntervalSegmentedControl.selectedSegmentTintColor = selectedColor
        } else {
            repeatIntervalSegmentedControl.tintColor = selectedColor
        }
        
        // 뷰모델 업데이트
        viewModel.updateColor(selectedColor)
    }
}
