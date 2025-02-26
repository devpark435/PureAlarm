//
//  CustomSwitch.swift
//  PureAlarm
//
//  Created by 박현렬 on 2/26/25.
//

import UIKit
import SnapKit
import Then

// MARK: - 커스텀 스위치
class CustomSwitch: UISwitch {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }
    
    private func configure() {
        onTintColor = UIColor(red: 0.4, green: 0.6, blue: 1.0, alpha: 1.0)
        transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
    }
}
