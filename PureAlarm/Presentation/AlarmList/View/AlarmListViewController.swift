//
//  ViewController.swift
//  PureAlarm
//
//  Created by 박현렬 on 2/26/25.
//

import UIKit
import SnapKit
import Then

final class AlarmListViewController: UIViewController {
    // MARK: - Properties
    private var alarms: [Alarm] = []
    
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
    
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 20
        layout.minimumInteritemSpacing = 0
        layout.sectionInset = UIEdgeInsets(top: 10, left: 20, bottom: 20, right: 20)
        layout.itemSize = CGSize(width: UIScreen.main.bounds.width - 40, height: 120)
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.showsVerticalScrollIndicator = false
        collectionView.register(AlarmCollectionViewCell.self, forCellWithReuseIdentifier: AlarmCollectionViewCell.identifier)
        collectionView.delegate = self
        collectionView.dataSource = self
        return collectionView
    }()
    
    private lazy var addButton = CircleButton().then {
        $0.addTarget(self, action: #selector(addButtonTapped), for: .touchUpInside)
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        setupDummyData()
    }
    
    // MARK: - UI Configuration
    private func configureUI() {
        view.addSubview(gradientBackgroundView)
        gradientBackgroundView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        view.addSubviews(headerView, sleepSummaryCard, collectionView, addButton)
        headerView.addSubviews(titleLabel, subtitleLabel)
        
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
        
        sleepSummaryCard.snp.makeConstraints {
            $0.top.equalTo(headerView.snp.bottom)
            $0.leading.equalToSuperview().offset(20)
            $0.trailing.equalToSuperview().offset(-20)
            $0.height.equalTo(140)
        }
        
        collectionView.snp.makeConstraints {
            $0.top.equalTo(sleepSummaryCard.snp.bottom).offset(20)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalToSuperview()
        }
        
        addButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-20)
            $0.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-20)
            $0.size.equalTo(60)
        }
    }
    
    // MARK: - Data Setup
    private func setupDummyData() {
        // 임시 데이터로 테스트
        let calendar = Calendar.current
        var dateComponents = DateComponents()
        dateComponents.hour = 7
        dateComponents.minute = 30
        
        let morningAlarm = Alarm(
            title: "기상 시간",
            time: calendar.date(from: dateComponents) ?? Date(),
            days: [.monday, .tuesday, .wednesday, .thursday, .friday],
            color: UIColor(red: 0.4, green: 0.6, blue: 1.0, alpha: 1.0)
        )
        
        dateComponents.hour = 22
        dateComponents.minute = 30
        
        let nightAlarm = Alarm(
            title: "취침 준비",
            time: calendar.date(from: dateComponents) ?? Date(),
            days: [.monday, .tuesday, .wednesday, .thursday, .friday, .saturday, .sunday],
            color: UIColor(red: 0.6, green: 0.2, blue: 0.8, alpha: 1.0)
        )
        
        dateComponents.hour = 9
        dateComponents.minute = 0
        
        let weekendAlarm = Alarm(
            title: "주말 기상",
            time: calendar.date(from: dateComponents) ?? Date(),
            days: [.saturday, .sunday],
            color: UIColor(red: 1.0, green: 0.5, blue: 0.3, alpha: 1.0)
        )
        
        alarms = [morningAlarm, nightAlarm, weekendAlarm]
    }
    
    // MARK: - Actions
    @objc private func addButtonTapped() {
        // TODO: 디테일 화면 이동 코드 추가
    }
}

// MARK: - CollectionView DataSource & Delegate
extension AlarmListViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return alarms.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: AlarmCollectionViewCell.identifier, for: indexPath) as? AlarmCollectionViewCell else {
            return UICollectionViewCell()
        }
        
        let alarm = alarms[indexPath.item]
        cell.configure(with: alarm)
        cell.toggleHandler = { isOn in
            print("알람 상태 변경: \(isOn)")
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // TODO: 디테일 화면 이동 코드 추가
    }
}
