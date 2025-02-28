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
    private let viewModel: AlarmListViewModel
    private var alarms: [Alarm] = []
    
    // 의존성 주입을 위한 생성자 추가
    init(viewModel: AlarmListViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
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
        $0.text = "알람"
        $0.textColor = .white
        $0.font = .systemFont(ofSize: 28, weight: .bold)
    }
    
    private let subtitleLabel = UILabel().then {
        $0.text = "규칙적인 알람으로 하루를 시작하세요"
        $0.textColor = UIColor(white: 0.7, alpha: 1.0)
        $0.font = .systemFont(ofSize: 14)
    }
    
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
    
    private let addButton = CircleButton()
    
    private let loadingIndicator = UIActivityIndicatorView(style: .large).then {
        $0.color = .white
        $0.hidesWhenStopped = true
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        bindViewModel()
        setupButtonActions()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.fetchAlarms()
    }
    
    // MARK: - UI Configuration
    private func configureUI() {
        view.addSubview(gradientBackgroundView)
        gradientBackgroundView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        view.addSubviews(headerView, collectionView, addButton, loadingIndicator)
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
        
        collectionView.snp.makeConstraints {
            $0.top.equalTo(headerView.snp.bottom)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalToSuperview()
        }
        
        addButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-20)
            $0.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-20)
            $0.size.equalTo(60)
        }
        
        loadingIndicator.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
    }
    
    private func setupButtonActions() {
        addButton.addTarget(self, action: #selector(addButtonTapped), for: .touchUpInside)
    }
    
    // MARK: - ViewModel Binding
    private func bindViewModel() {
        viewModel.alarmsBinding = { [weak self] alarms in
            guard let self = self else { return }
            self.alarms = alarms
            self.collectionView.reloadData()
            
            // 알람이 없을 때와 있을 때 UI 상태 설정
            if alarms.isEmpty {
                self.showEmptyState()
            } else {
                self.hideEmptyState()
            }
        }
        
        viewModel.loadingBinding = { [weak self] isLoading in
            guard let self = self else { return }
            if isLoading {
                self.loadingIndicator.startAnimating()
            } else {
                self.loadingIndicator.stopAnimating()
            }
        }
        
        viewModel.errorBinding = { [weak self] error in
            guard let self = self else { return }
            self.showErrorAlert(message: error)
        }
    }
    
    // MARK: - Helper Methods
    private func showEmptyState() {
        // 알람이 없을 때 표시할 UI (예: 안내 메시지 등)
    }
    
    private func hideEmptyState() {
        // 알람이 있을 때 빈 상태 UI 숨기기
    }
    
    private func showErrorAlert(message: String) {
        let alert = UIAlertController(title: "알림", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
    
    // MARK: - Actions
    @objc private func addButtonTapped() {
        let detailViewModel = AlarmDetailViewModel()
        let detailVC = AlarmDetailViewController(viewModel: detailViewModel)
        
        detailViewModel.alarmSavedHandler = { [weak self] alarm in
            self?.viewModel.addAlarm(alarm)
        }
        
        present(detailVC, animated: true)
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
        
        // 알람의 ID를 사용하여 올바른 알람 토글
        cell.toggleHandler = { [weak self, alarm] isOn in
            // 뷰모델 업데이트 (ID로 알람 찾기)
            self?.viewModel.toggleAlarmWithId(alarm.id, isActive: isOn)
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let alarm = viewModel.getAlarm(at: indexPath.item) else { return }
        
        let detailViewModel = AlarmDetailViewModel(alarm: alarm)
        let detailVC = AlarmDetailViewController(viewModel: detailViewModel)
        
        detailViewModel.alarmSavedHandler = { [weak self] updatedAlarm in
            self?.viewModel.updateAlarm(updatedAlarm)
        }
        
        detailViewModel.alarmDeletedHandler = { [weak self] in
            self?.viewModel.deleteAlarm(at: indexPath.item)
        }
        
        present(detailVC, animated: true)
    }
}
