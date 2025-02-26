//
//  CustomTextField.swift
//  PureAlarm
//
//  Created by 박현렬 on 2/26/25.
//

import UIKit
import SnapKit
import Then

// MARK: - 커스텀 텍스트 필드
class CustomTextField: UITextField {
    
    private let padding = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 15)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupTextField()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupTextField()
    }
    
    private func setupTextField() {
        backgroundColor = UIColor(white: 0.2, alpha: 1.0)
        layer.cornerRadius = 10
        textColor = .white
        tintColor = UIColor(red: 0.4, green: 0.6, blue: 1.0, alpha: 1.0)
        
        // 플레이스홀더 스타일
        attributedPlaceholder = NSAttributedString(
            string: placeholder ?? "",
            attributes: [NSAttributedString.Key.foregroundColor: UIColor(white: 0.7, alpha: 1.0)]
        )
        
        // 클리어 버튼 스타일
        clearButtonMode = .whileEditing
    }
    
    override func textRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: padding)
    }
    
    override func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: padding)
    }
    
    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: padding)
    }
}
