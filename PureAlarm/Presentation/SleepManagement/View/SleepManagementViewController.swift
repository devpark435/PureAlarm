//
//  SleepManagementViewController.swift
//  PureAlarm
//
//  Created by 박현렬 on 2/26/25.
//

import UIKit
import SnapKit
import Then

final class SleepManagementViewController: UIViewController {
    // MARK: - Properties
    private var sleepRecords: [SleepRecord] = []
    
    // MARK: - UI Components
    private let gradientBackgroundView = GradientView(
        colors: [
            UIColor(red: 0.11, green: 0.11, blue: 0.18, alpha: 1.0),
            UIColor(red: 0.05, green: 0.05, blue: 0.1, alpha: 1.0)
        ]
    )
    
    private let headerView = UIView().then {
        $0.backgroundColor = .clear
    }
    
    private let titleLabel = UILabel().then {
        $0.text = "수면 관리"
        $0.textColor = .white
        $0.font = .systemFont(ofSize: 28, weight: .bold)
    }
    
    private let subtitleLabel = UILabel().then {
        $0.text = "규칙적인 수면 습관이 건강한 하루를 만듭니다"
        $0.textColor = UIColor(white: 0.7, alpha: 1.0)
        $0.font = .systemFont(ofSize: 14)
    }
    
    private let sleepSummaryCard = SleepSummaryCardView()
    
    private let sleepScheduleCard = UIView().then {
        $0.backgroundColor = UIColor(red: 0.2, green: 0.2, blue: 0.3, alpha: 1.0)
        $0.layer.cornerRadius = 20
    }
    
    private let sleepScheduleTitle = UILabel().then {
        $0.text = "수면 일정"
        $0.textColor = .white
        $0.font = .systemFont(ofSize: 18, weight: .bold)
    }
    
    private let bedTimeLabel = UILabel().then {
        $0.text = "취침 시간"
        $0.textColor = UIColor(white: 0.7, alpha: 1.0)
        $0.font = .systemFont(ofSize: 14)
    }
    
    private let bedTimeValueLabel = UILabel().then {
        $0.text = "오후 10:30"
        $0.textColor = .white
        $0.font = .systemFont(ofSize: 18, weight: .medium)
    }
    
    private let wakeTimeLabel = UILabel().then {
        $0.text = "기상 시간"
        $0.textColor = UIColor(white: 0.7, alpha: 1.0)
        $0.font = .systemFont(ofSize: 14)
    }
    
    private let wakeTimeValueLabel = UILabel().then {
        $0.text = "오전 7:00"
        $0.textColor = .white
        $0.font = .systemFont(ofSize: 18, weight: .medium)
    }
    
    private let editScheduleButton = UIButton().then {
        $0.setTitle("일정 편집", for: .normal)
        $0.setTitleColor(.white, for: .normal)
        $0.backgroundColor = UIColor(red: 0.4, green: 0.6, blue: 1.0, alpha: 1.0)
        $0.layer.cornerRadius = 12
    }
    
    private let weeklyAnalysisCard = UIView().then {
        $0.backgroundColor = UIColor(red: 0.2, green: 0.2, blue: 0.3, alpha: 1.0)
        $0.layer.cornerRadius = 20
    }
    
    private let weeklyAnalysisTitle = UILabel().then {
        $0.text = "주간 수면 분석"
        $0.textColor = .white
        $0.font = .systemFont(ofSize: 18, weight: .bold)
    }
    
    private let weeklyAnalysisGraph = WeeklyAnalysisGraphView()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        setupDummyData()
        setupButtonActions()
    }
    
    // MARK: - UI Configuration
    private func configureUI() {
        view.addSubview(gradientBackgroundView)
        gradientBackgroundView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        // 메인 뷰 구성요소 추가
        view.addSubviews(headerView, sleepSummaryCard, sleepScheduleCard, weeklyAnalysisCard)
        headerView.addSubviews(titleLabel, subtitleLabel)
        
        // 헤더 뷰 제약 조건
        headerView.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(80)
        }
        
        titleLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(10)
            $0.leading.equalToSuperview().offset(20)
        }
        
        subtitleLabel.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(4)
            $0.leading.equalTo(titleLabel)
        }
        
        // 수면 요약 카드 제약 조건
        sleepSummaryCard.snp.makeConstraints {
            $0.top.equalTo(headerView.snp.bottom)
            $0.leading.equalToSuperview().offset(20)
            $0.trailing.equalToSuperview().offset(-20)
            $0.height.equalTo(140)
        }
        
        // 수면 일정 카드 구성 및 제약 조건
        sleepScheduleCard.addSubviews(
            sleepScheduleTitle,
            bedTimeLabel, bedTimeValueLabel,
            wakeTimeLabel, wakeTimeValueLabel,
            editScheduleButton
        )
        
        sleepScheduleCard.snp.makeConstraints {
            $0.top.equalTo(sleepSummaryCard.snp.bottom).offset(20)
            $0.leading.equalToSuperview().offset(20)
            $0.trailing.equalToSuperview().offset(-20)
            $0.height.equalTo(160)
        }
        
        sleepScheduleTitle.snp.makeConstraints {
            $0.top.leading.equalToSuperview().offset(16)
        }
        
        bedTimeLabel.snp.makeConstraints {
            $0.top.equalTo(sleepScheduleTitle.snp.bottom).offset(16)
            $0.leading.equalToSuperview().offset(16)
        }
        
        bedTimeValueLabel.snp.makeConstraints {
            $0.top.equalTo(bedTimeLabel.snp.bottom).offset(4)
            $0.leading.equalToSuperview().offset(16)
        }
        
        wakeTimeLabel.snp.makeConstraints {
            $0.top.equalTo(sleepScheduleTitle.snp.bottom).offset(16)
            $0.leading.equalTo(bedTimeValueLabel.snp.trailing).offset(30)
        }
        
        wakeTimeValueLabel.snp.makeConstraints {
            $0.top.equalTo(wakeTimeLabel.snp.bottom).offset(4)
            $0.leading.equalTo(wakeTimeLabel)
        }
        
        editScheduleButton.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.bottom.equalToSuperview().offset(-16)
            $0.width.equalTo(120)
            $0.height.equalTo(36)
        }
        
        // 주간 분석 카드 구성 및 제약 조건
        weeklyAnalysisCard.addSubviews(weeklyAnalysisTitle, weeklyAnalysisGraph)
        
        weeklyAnalysisCard.snp.makeConstraints {
            $0.top.equalTo(sleepScheduleCard.snp.bottom).offset(20)
            $0.leading.equalToSuperview().offset(20)
            $0.trailing.equalToSuperview().offset(-20)
            $0.height.equalTo(200)
            $0.bottom.lessThanOrEqualTo(view.safeAreaLayoutGuide.snp.bottom).offset(-20)
        }
        
        weeklyAnalysisTitle.snp.makeConstraints {
            $0.top.leading.equalToSuperview().offset(16)
        }
        
        weeklyAnalysisGraph.snp.makeConstraints {
            $0.top.equalTo(weeklyAnalysisTitle.snp.bottom).offset(16)
            $0.leading.equalToSuperview().offset(16)
            $0.trailing.equalToSuperview().offset(-16)
            $0.bottom.equalToSuperview().offset(-16)
        }
        
        // 그림자 효과 추가
        [sleepSummaryCard, sleepScheduleCard, weeklyAnalysisCard].forEach { view in
            view.layer.shadowColor = UIColor.black.cgColor
            view.layer.shadowOffset = CGSize(width: 0, height: 6)
            view.layer.shadowRadius = 10
            view.layer.shadowOpacity = 0.3
        }
    }
    
    private func setupButtonActions() {
        // 버튼 액션 설정
        editScheduleButton.addTarget(self, action: #selector(editScheduleTapped), for: .touchUpInside)
    }
    
    // MARK: - Data Setup
    private func setupDummyData() {
        // 더미 데이터 설정 예시
        sleepRecords = [
            SleepRecord(date: "2월 20일", duration: 7.5, quality: .good),
            SleepRecord(date: "2월 21일", duration: 6.8, quality: .fair),
            SleepRecord(date: "2월 22일", duration: 7.2, quality: .good),
            SleepRecord(date: "2월 23일", duration: 8.0, quality: .excellent),
            SleepRecord(date: "2월 24일", duration: 6.5, quality: .fair),
            SleepRecord(date: "2월 25일", duration: 7.1, quality: .good),
            SleepRecord(date: "2월 26일", duration: 7.4, quality: .good)
        ]
    }
    
    // MARK: - Actions
    @objc private func editScheduleTapped() {
        // 수면 일정 편집 화면으로 이동
        print("수면 일정 편집 버튼 탭됨")
    }
}

// MARK: - 수면 기록 모델
struct SleepRecord {
    enum Quality {
        case poor, fair, good, excellent
        
        var color: UIColor {
            switch self {
            case .poor: return UIColor(red: 0.9, green: 0.3, blue: 0.3, alpha: 1.0)
            case .fair: return UIColor(red: 0.9, green: 0.6, blue: 0.3, alpha: 1.0)
            case .good: return UIColor(red: 0.3, green: 0.7, blue: 0.9, alpha: 1.0)
            case .excellent: return UIColor(red: 0.3, green: 0.9, blue: 0.5, alpha: 1.0)
            }
        }
    }
    
    let date: String
    let duration: Double // 시간 단위
    let quality: Quality
}

// MARK: - 주간 분석 그래프 뷰
final class WeeklyAnalysisGraphView: UIView {
    
    private var sleepRecords: [SleepRecord] = []
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(with records: [SleepRecord]) {
        self.sleepRecords = records
        setNeedsDisplay()
    }
    
    override func draw(_ rect: CGRect) {
        guard !sleepRecords.isEmpty, let context = UIGraphicsGetCurrentContext() else {
            drawPlaceholderGraph(in: rect)
            return
        }
        
        let width = rect.width
        let height = rect.height
        let maxDuration: CGFloat = 10.0 // 최대 수면 시간 (그래프 y축 기준)
        let barWidth: CGFloat = width / CGFloat(7) - 10
        
        // 막대 그래프 그리기
        for (index, value) in [7.5, 6.8, 7.2, 8.0, 6.5, 7.1, 7.4].enumerated() {
            let normalizedValue = CGFloat(value) / maxDuration
            let barHeight = height * normalizedValue * 0.8 // 그래프의 80%만 사용
            let x = CGFloat(index) * (barWidth + 10) + 5
            let y = height - barHeight - 20 // 바닥에서 약간 띄우기
            
            // 막대 그래프 그리기
            let barRect = CGRect(x: x, y: y, width: barWidth, height: barHeight)
            let path = UIBezierPath(roundedRect: barRect, cornerRadius: 4)
            
            let dayColor: UIColor
            switch index % 4 {
            case 0: dayColor = UIColor(red: 0.3, green: 0.7, blue: 0.9, alpha: 1.0) // 좋음
            case 1: dayColor = UIColor(red: 0.9, green: 0.6, blue: 0.3, alpha: 1.0) // 보통
            case 2: dayColor = UIColor(red: 0.3, green: 0.9, blue: 0.5, alpha: 1.0) // 우수
            case 3: dayColor = UIColor(red: 0.3, green: 0.7, blue: 0.9, alpha: 1.0) // 좋음
            default: dayColor = UIColor.gray
            }
            
            dayColor.setFill()
            path.fill()
            
            // 요일 표시
            let days = ["월", "화", "수", "목", "금", "토", "일"]
            let day = days[index]
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12),
                .foregroundColor: UIColor(white: 0.7, alpha: 1.0)
            ]
            
            let dayString = NSAttributedString(string: day, attributes: attributes)
            let stringSize = dayString.size()
            let stringX = x + (barWidth - stringSize.width) / 2
            let stringY = height - 15
            
            dayString.draw(at: CGPoint(x: stringX, y: stringY))
            
            // 시간 표시
            let hourString = NSAttributedString(string: "\(value)", attributes: attributes)
            let hourSize = hourString.size()
            let hourX = x + (barWidth - hourSize.width) / 2
            let hourY = y - hourSize.height - 5
            
            hourString.draw(at: CGPoint(x: hourX, y: hourY))
        }
    }
    
    private func drawPlaceholderGraph(in rect: CGRect) {
        // 데이터가 없을 때 보여줄 플레이스홀더 그래프 (예: 안내 메시지 등)
        let text = "수면 데이터가 없습니다"
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14),
            .foregroundColor: UIColor(white: 0.7, alpha: 1.0)
        ]
        
        let attributedText = NSAttributedString(string: text, attributes: attributes)
        let textSize = attributedText.size()
        let point = CGPoint(
            x: (rect.width - textSize.width) / 2,
            y: (rect.height - textSize.height) / 2
        )
        
        attributedText.draw(at: point)
    }
}
