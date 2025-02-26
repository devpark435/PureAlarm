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
    
    private lazy var toggleSwitch = CustomSwitch().then {
        $0.addTarget(self, action: #selector(switchToggled), for: .valueChanged)
    }
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
    
    // MARK: - Configuration
    func configure(with alarm: Alarm) {
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
        
        toggleSwitch.isOn = alarm.isActive
        colorIndicator.backgroundColor = alarm.color
        
        // 알람이 켜져 있을 때 색상 효과
        if alarm.isActive {
            containerView.layer.borderWidth = 1
            containerView.layer.borderColor = alarm.color.withAlphaComponent(0.5).cgColor
        } else {
            containerView.layer.borderWidth = 0
        }
    }
    
    // MARK: - Actions
    @objc private func switchToggled() {
        toggleHandler?(toggleSwitch.isOn)
        
        // 애니메이션 효과
        UIView.animate(withDuration: 0.3) {
            self.timeLabel.alpha = self.toggleSwitch.isOn ? 1.0 : 0.5
            self.titleLabel.alpha = self.toggleSwitch.isOn ? 1.0 : 0.5
        }
    }
}
