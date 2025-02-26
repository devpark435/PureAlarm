//
//  AlarmCell.swift
//  PureAlarm
//
//  Created by 박현렬 on 2/26/25.
//

import UIKit
import SnapKit
import Then

final class AlarmCell: UITableViewCell {
    static let identifier = "AlarmCell"
    
    // MARK: - UI Components
    private let timeLabel = UILabel().then {
        $0.textColor = .white
        $0.font = .systemFont(ofSize: 48, weight: .light)
    }
    
    private let titleLabel = UILabel().then {
        $0.textColor = .gray
        $0.font = .systemFont(ofSize: 16)
    }
    
    private let daysLabel = UILabel().then {
        $0.textColor = .gray
        $0.font = .systemFont(ofSize: 14)
    }
    
    private lazy var toggleSwitch = UISwitch().then {
        $0.onTintColor = .orange
        $0.addTarget(self, action: #selector(switchToggled), for: .valueChanged)
    }
    
    // MARK: - Initialization
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UI Configuration
    private func configureUI() {
        backgroundColor = .black
        selectionStyle = .none
        
        contentView.addSubviews(timeLabel, titleLabel, daysLabel, toggleSwitch)
        
        timeLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(12)
            $0.leading.equalToSuperview().offset(16)
        }
        
        titleLabel.snp.makeConstraints {
            $0.top.equalTo(timeLabel.snp.bottom).offset(4)
            $0.leading.equalToSuperview().offset(16)
        }
        
        daysLabel.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(4)
            $0.leading.equalToSuperview().offset(16)
            $0.bottom.equalToSuperview().offset(-12)
        }
        
        toggleSwitch.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.trailing.equalToSuperview().offset(-16)
        }
    }
    
    // MARK: - Configuration
    func configure(with alarm: Alarm) {
        timeLabel.text = alarm.time.getFormattedTime()
        titleLabel.text = alarm.title
        
        if alarm.days.isEmpty {
            daysLabel.text = "알람"
        } else {
            let daysText = alarm.days.map { $0.shortName }.joined(separator: " ")
            daysLabel.text = daysText
        }
        
        toggleSwitch.isOn = alarm.isActive
    }
    
    // MARK: - Actions
    @objc private func switchToggled() {
        // UI 단계에서는 토글 동작만 구현
        print("알람 토글 상태 변경: \(toggleSwitch.isOn)")
    }
}
