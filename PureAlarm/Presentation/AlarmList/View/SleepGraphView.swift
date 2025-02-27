//
//  SleepGraphView.swift
//  PureAlarm
//
//  Created by 박현렬 on 2/26/25.
//

import UIKit
import SnapKit
import Then

// MARK: - 수면 그래프 뷰
final class SleepGraphView: UIView {
    
    // MARK: - Properties
    private let sleepData: [CGFloat] = [6.8, 7.2, 6.5, 7.8, 8.0, 7.5, 7.0]
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Drawing
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        let width = rect.width
        let height = rect.height
        let maxValue: CGFloat = 10.0
        let barWidth: CGFloat = width / CGFloat(sleepData.count) - 4
        
        for (index, value) in sleepData.enumerated() {
            let normalizedValue = value / maxValue
            let barHeight = height * normalizedValue
            let x = CGFloat(index) * (barWidth + 4)
            let y = height - barHeight
            
            let gradient = CGGradient(
                colorsSpace: nil,
                colors: [
                    UIColor(red: 0.4, green: 0.6, blue: 1.0, alpha: 1.0).cgColor,
                    UIColor(red: 0.6, green: 0.3, blue: 0.9, alpha: 1.0).cgColor
                ] as CFArray,
                locations: [0.0, 1.0]
            )!
            
            let barRect = CGRect(x: x, y: y, width: barWidth, height: barHeight)
            let path = UIBezierPath(roundedRect: barRect, cornerRadius: 4)
            
            context.saveGState()
            context.addPath(path.cgPath)
            context.clip()
            
            context.drawLinearGradient(
                gradient,
                start: CGPoint(x: x, y: y),
                end: CGPoint(x: x, y: y + barHeight),
                options: []
            )
            
            context.restoreGState()
        }
    }
}

