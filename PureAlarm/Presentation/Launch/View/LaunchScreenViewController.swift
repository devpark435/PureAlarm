//
//  LaunchScreenViewController.swift
//  PureAlarm
//
//  Created by 박현렬 on 3/2/25.
//

import UIKit

// 런치스크린 완료 알림을 위한 프로토콜
protocol LaunchScreenViewControllerDelegate: AnyObject {
    func launchScreenFinished()
}

class LaunchScreenViewController: UIViewController {
    
    weak var delegate: LaunchScreenViewControllerDelegate?
    
    private let logoImageView = UIImageView().then {
        $0.contentMode = .scaleAspectFit
        $0.image = UIImage(systemName: "alarm.fill")?.withRenderingMode(.alwaysTemplate)
        // TODO: 로고 이미지 에셋 추가 시 변경
        // $0.image = UIImage(named: "LaunchLogo")
        $0.tintColor = .white
    }
    
    private let titleLabel = UILabel().then {
        $0.text = "PureAlarm"
        $0.textColor = .white
        $0.font = .systemFont(ofSize: 28, weight: .bold)
        $0.textAlignment = .center
    }
    
    private let subtitleLabel = UILabel().then {
        $0.text = "규칙적인 알람으로 하루를 시작하세요"
        $0.textColor = UIColor(white: 0.7, alpha: 1.0)
        $0.font = .systemFont(ofSize: 14)
        $0.textAlignment = .center
    }
    
    private let gradientBackgroundView = GradientView(
        colors: [
            UIColor(red: 0.11, green: 0.11, blue: 0.18, alpha: 1.0),
            UIColor(red: 0.05, green: 0.05, blue: 0.1, alpha: 1.0)
        ]
    )
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        
        // 2초 후 메인 화면으로 전환
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.delegate?.launchScreenFinished()
        }
    }
    
    private func configureUI() {
        // 그라데이션 배경 추가
        view.addSubview(gradientBackgroundView)
        gradientBackgroundView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        // 로고 이미지 추가
        view.addSubview(logoImageView)
        logoImageView.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.centerY.equalToSuperview().offset(-20)
            $0.width.height.equalTo(150)
        }
        
        // 앱 이름 레이블 추가
        view.addSubview(titleLabel)
        titleLabel.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalTo(logoImageView.snp.bottom).offset(20)
        }
        
        // 서브타이틀 레이블 추가
        view.addSubview(subtitleLabel)
        subtitleLabel.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalTo(titleLabel.snp.bottom).offset(8)
        }
    }
}
