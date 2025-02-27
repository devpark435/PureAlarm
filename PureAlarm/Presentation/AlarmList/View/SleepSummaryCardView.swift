//
//  SleepSummaryCardView.swift
//  PureAlarm
//
//  Created by 박현렬 on 2/26/25.
//

import UIKit
import SnapKit
import Then

// MARK: - 수면 요약 카드 뷰
final class SleepSummaryCardView: UIView {
    
    // MARK: - UI Components
    private let containerView = UIView().then {
        $0.backgroundColor = UIColor(red: 0.2, green: 0.2, blue: 0.3, alpha: 1.0)
        $0.layer.cornerRadius = 20
    }
    
    private let titleLabel = UILabel().then {
        $0.text = "수면 통계"
        $0.textColor = .white
        $0.font = .systemFont(ofSize: 18, weight: .bold)
    }
    
    private let sleepTimeLabel = UILabel().then {
        $0.text = "평균 수면 시간"
        $0.textColor = UIColor(white: 0.7, alpha: 1.0)
        $0.font = .systemFont(ofSize: 12)
    }
    
    private let sleepTimeValueLabel = UILabel().then {
        $0.text = "7시간 42분"
        $0.textColor = .white
        $0.font = .systemFont(ofSize: 22, weight: .semibold)
    }
    
    private let sleepQualityLabel = UILabel().then {
        $0.text = "수면 품질"
        $0.textColor = UIColor(white: 0.7, alpha: 1.0)
        $0.font = .systemFont(ofSize: 12)
    }
    
    private let sleepQualityValueLabel = UILabel().then {
        $0.text = "양호"
        $0.textColor = UIColor(red: 0.4, green: 0.8, blue: 0.4, alpha: 1.0)
        $0.font = .systemFont(ofSize: 22, weight: .semibold)
    }
    
    private let sleepGraphView = SleepGraphView()
    
    // MARK: - Initialization
    init() {
        super.init(frame: .zero)
        configureUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UI Configuration
    private func configureUI() {
        addSubview(containerView)
        containerView.addSubviews(titleLabel, sleepTimeLabel, sleepTimeValueLabel, sleepQualityLabel, sleepQualityValueLabel, sleepGraphView)
        
        containerView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        titleLabel.snp.makeConstraints {
            $0.top.leading.equalToSuperview().offset(16)
        }
        
        sleepTimeLabel.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(16)
            $0.leading.equalToSuperview().offset(16)
        }
        
        sleepTimeValueLabel.snp.makeConstraints {
            $0.top.equalTo(sleepTimeLabel.snp.bottom).offset(4)
            $0.leading.equalToSuperview().offset(16)
        }
        
        sleepQualityLabel.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(16)
            $0.leading.equalTo(sleepTimeValueLabel.snp.trailing).offset(30)
        }
        
        sleepQualityValueLabel.snp.makeConstraints {
            $0.top.equalTo(sleepQualityLabel.snp.bottom).offset(4)
            $0.leading.equalTo(sleepQualityLabel)
        }
        
        sleepGraphView.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(10)
            $0.trailing.equalToSuperview().offset(-16)
            $0.width.equalTo(120)
            $0.height.equalTo(80)
        }
        
        // 그림자 효과
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOffset = CGSize(width: 0, height: 6)
        containerView.layer.shadowRadius = 10
        containerView.layer.shadowOpacity = 0.3
    }
}

