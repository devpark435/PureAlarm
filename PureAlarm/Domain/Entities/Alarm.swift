//
//  Alarm.swift
//  PureAlarm
//
//  Created by 박현렬 on 2/26/25.
//

import Foundation
import UIKit

struct Alarm: Codable {
    let id: UUID
    var title: String
    var time: Date
    var days: [WeekDay]
    var isActive: Bool
    var sound: String
    var vibration: Bool
    var snooze: Bool
    var repeatInterval: Int // 추가: 0은 반복 없음, 그 외는 분 단위 반복 간격
    private var colorData: ColorData
    
    var color: UIColor {
        get {
            return UIColor(red: colorData.red, green: colorData.green, blue: colorData.blue, alpha: colorData.alpha)
        }
        set {
            var red: CGFloat = 0
            var green: CGFloat = 0
            var blue: CGFloat = 0
            var alpha: CGFloat = 0
            newValue.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
            colorData = ColorData(red: red, green: green, blue: blue, alpha: alpha)
        }
    }
    
    init(id: UUID = UUID(), title: String, time: Date, days: [WeekDay] = [], isActive: Bool = true, sound: String = "Default", vibration: Bool = true, snooze: Bool = true, repeatInterval: Int = 0, color: UIColor = UIColor(red: 0.4, green: 0.6, blue: 1.0, alpha: 1.0)) {
        self.id = id
        self.title = title
        self.time = time
        self.days = days
        self.isActive = isActive
        self.sound = sound
        self.vibration = vibration
        self.snooze = snooze
        self.repeatInterval = repeatInterval
        
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        self.colorData = ColorData(red: red, green: green, blue: blue, alpha: alpha)
    }
    
    // 색상 저장을 위한 내부 구조체
    struct ColorData: Codable {
        let red: CGFloat
        let green: CGFloat
        let blue: CGFloat
        let alpha: CGFloat
    }
}

enum WeekDay: Int, Codable, CaseIterable {
    case sunday = 1
    case monday = 2
    case tuesday = 3
    case wednesday = 4
    case thursday = 5
    case friday = 6
    case saturday = 7
    
    var shortName: String {
        switch self {
        case .sunday: return "일"
        case .monday: return "월"
        case .tuesday: return "화"
        case .wednesday: return "수"
        case .thursday: return "목"
        case .friday: return "금"
        case .saturday: return "토"
        }
    }
}
