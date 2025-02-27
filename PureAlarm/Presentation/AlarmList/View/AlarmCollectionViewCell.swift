//
//  AlarmCell.swift
//  PureAlarm
//
//  Created by 박현렬 on 2/26/25.
//

import UIKit
import SnapKit
import Then

final class AlarmCollectionViewCell: UICollectionViewCell {
    static let identifier = "AlarmCollectionViewCell"
    
    // MARK: - Properties
    var toggleHandler: ((Bool) -> Void)?
    private var currentAlarm: Alarm?
    
    // MARK: - UI Components
    private let containerView = UIView().then {
        $0.backgroundColor = UIColor(white: 0.15, alpha: 1.0)
        $0.layer.cornerRadius = 16
    }
    
    private let colorIndicator = UIView().then {
        $0.layer.cornerRadius = 3
    }
    
    private let timeLabel = UILabel().then {
        $0.textColor = .white
        $0.font = .systemFont(ofSize: 36, weight: .medium)
    }
    
    private let amPmLabel = UILabel().then {
        $0.textColor = UIColor(white: 0.7, alpha: 1.0)
        $0.font = .systemFont(ofSize: 14, weight: .medium)
    }
    
    private let titleLabel = UILabel().then {
        $0.textColor = .white
        $0.font = .systemFont(ofSize: 16, weight: .semibold)
    }
    
    private let daysLabel = UILabel().then {
        $0.textColor = UIColor(white: 0.7, alpha: 1.0)
        $0.font = .systemFont(ofSize: 12)
    }
    
    private lazy var toggleSwitch = CustomSwitch()
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureUI()
        setupActions()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        // 셀 재사용 시 이전 상태 초기화
        currentAlarm = nil
        toggleHandler = nil
        
        // 스위치 타겟 초기화
        toggleSwitch.removeTarget(nil, action: nil, for: .valueChanged)
        setupActions()
    }
    
    // MARK: - UI Configuration
    private func configureUI() {
        contentView.addSubview(containerView)
        containerView.addSubviews(colorIndicator, timeLabel, amPmLabel, titleLabel, daysLabel, toggleSwitch)
        
        containerView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        colorIndicator.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.top.equalToSuperview().offset(16)
            $0.size.equalTo(6)
        }
        
        timeLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.top.equalTo(colorIndicator.snp.bottom).offset(8)
        }
        
        amPmLabel.snp.makeConstraints {
            $0.leading.equalTo(timeLabel.snp.trailing).offset(4)
            $0.bottom.equalTo(timeLabel.snp.bottom).offset(-8)
        }
        
        titleLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.top.equalTo(timeLabel.snp.bottom).offset(8)
        }
        
        daysLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.top.equalTo(titleLabel.snp.bottom).offset(4)
            $0.bottom.equalToSuperview().offset(-16)
        }
        
        toggleSwitch.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.trailing.equalToSuperview().offset(-16)
        }
        
        // 그림자 효과
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOffset = CGSize(width: 0, height: 4)
        containerView.layer.shadowRadius = 8
        containerView.layer.shadowOpacity = 0.2
    }
    
    private func setupActions() {
        toggleSwitch.addTarget(self, action: #selector(switchToggled), for: .valueChanged)
    }
    
    // MARK: - Configuration
    func configure(with alarm: Alarm) {
        // 현재 알람 저장
        currentAlarm = alarm
        
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm"
        timeLabel.text = formatter.string(from: alarm.time)
        
        formatter.dateFormat = "a"
        amPmLabel.text = formatter.string(from: alarm.time)
        
        titleLabel.text = alarm.title
        
        if alarm.days.isEmpty {
            daysLabel.text = "매일"
        } else {
            let daysText = alarm.days.map { $0.shortName }.joined(separator: " ")
            daysLabel.text = daysText
        }
        
        // 스위치 상태를 설정하기 전에 타겟 일시 제거
        toggleSwitch.removeTarget(self, action: #selector(switchToggled), for: .valueChanged)
        toggleSwitch.isOn = alarm.isActive
        toggleSwitch.addTarget(self, action: #selector(switchToggled), for: .valueChanged)
        
        colorIndicator.backgroundColor = alarm.color
        
        // 활성화 상태에 따른 시각적 상태 업데이트
        updateVisualFeedback(isActive: alarm.isActive)
    }
    
    // 알람 활성화 상태에 따른 UI 업데이트
    private func updateVisualFeedback(isActive: Bool) {
        // 텍스트 투명도 조정
        timeLabel.alpha = isActive ? 1.0 : 0.5
        titleLabel.alpha = isActive ? 1.0 : 0.5
        amPmLabel.alpha = isActive ? 1.0 : 0.5
        daysLabel.alpha = isActive ? 1.0 : 0.5
        
        // 테두리 스타일 조정
        if isActive && currentAlarm != nil {
            containerView.layer.borderWidth = 1
            containerView.layer.borderColor = currentAlarm?.color.withAlphaComponent(0.5).cgColor
        } else {
            containerView.layer.borderWidth = 0
        }
    }
    
    // MARK: - Actions
    @objc private func switchToggled() {
        // 이벤트 중복 방지
        toggleSwitch.removeTarget(self, action: #selector(switchToggled), for: .valueChanged)
        
        let isOn = toggleSwitch.isOn
        
        // 즉시 UI 업데이트
        updateVisualFeedback(isActive: isOn)
        
        // 핸들러 호출 (뷰컨트롤러에서 알람 상태 업데이트)
        toggleHandler?(isOn)
        
        // 이벤트 다시 연결
        DispatchQueue.main.async { [weak self] in
            self?.toggleSwitch.addTarget(self, action: #selector(self?.switchToggled), for: .valueChanged)
        }
    }
}
