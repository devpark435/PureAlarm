//
//  Alarm.swift
//  PureAlarm
//
//  Created by 박현렬 on 2/26/25.
//

import Foundation
import UIKit

struct Alarm {
    let id: UUID
    var title: String
    var time: Date
    var days: [WeekDay]
    var isActive: Bool
    var sound: String
    var vibration: Bool
    var snooze: Bool
    var color: UIColor
    
    init(
        id: UUID = UUID(),
        title: String,
        time: Date,
        days: [WeekDay] = [],
        isActive: Bool = true,
        sound: String = "Default",
        vibration: Bool = true,
        snooze: Bool = true,
        color: UIColor = UIColor(red: 0.4, green: 0.6, blue: 1.0, alpha: 1.0)
    ) {
        self.id = id
        self.title = title
        self.time = time
        self.days = days
        self.isActive = isActive
        self.sound = sound
        self.vibration = vibration
        self.snooze = snooze
        self.color = color
    }
}

enum WeekDay: Int, CaseIterable {
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
