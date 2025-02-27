//
//  CircleButton.swift
//  PureAlarm
//
//  Created by 박현렬 on 2/26/25.
//

import UIKit
import SnapKit
import Then

// MARK: - 원형 버튼
class CircleButton: UIButton {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        // 기본 설정
        let buttonColor = UIColor(red: 0.4, green: 0.6, blue: 1.0, alpha: 1.0)
        
        // Configuration 설정
        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: "plus")
        config.baseForegroundColor = .white
        
        // 배경을 완전히 투명하게 설정
        config.background.backgroundColor = .clear
        
        // 터치 효과 없애기
        config.background.backgroundColorTransformer = nil
        
        configuration = config
        
        // 레이어 속성으로 원형 배경 설정
        backgroundColor = buttonColor
        layer.cornerRadius = 30
        clipsToBounds = false // 그림자가 잘리지 않도록
        
        // 그림자 효과
        layer.shadowColor = buttonColor.withAlphaComponent(0.6).cgColor
        layer.shadowOffset = CGSize(width: 0, height: 4)
        layer.shadowRadius = 8
        layer.shadowOpacity = 0.8
        
        // 터치 효과 - 애니메이션으로 구현
        addTarget(self, action: #selector(touchDown), for: .touchDown)
        addTarget(self, action: #selector(touchUp), for: [.touchUpInside, .touchUpOutside, .touchCancel])
    }
    
    @objc private func touchDown() {
        UIView.animate(withDuration: 0.1) {
            self.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
            self.backgroundColor = self.backgroundColor?.withAlphaComponent(0.8)
        }
    }
    
    @objc private func touchUp() {
        let buttonColor = UIColor(red: 0.4, green: 0.6, blue: 1.0, alpha: 1.0)
        UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.5, options: [], animations: {
            self.transform = .identity
            self.backgroundColor = buttonColor
        })
    }
}
