//
//  AlarmDetailViewModel.swift
//  PureAlarm
//
//  Created by 박현렬 on 2/27/25.
//

import Foundation
import UIKit

final class AlarmDetailViewModel {
    // MARK: - Properties
    private var alarm: Alarm
    private(set) var isEditMode: Bool
    
    // MARK: - Outputs
    var alarmSavedHandler: ((Alarm) -> Void)?
    var alarmDeletedHandler: (() -> Void)?
    var errorBinding: ((String) -> Void)?
    
    // MARK: - Computed Properties
    var title: String {
        return alarm.title
    }
    
    var time: Date {
        return alarm.time
    }
    
    var selectedDays: [WeekDay] {
        return alarm.days
    }
    
    var selectedColor: UIColor {
        return alarm.color
    }
    
    var isActive: Bool {
        return alarm.isActive
    }
    
    // MARK: - Initialization
    init(alarm: Alarm? = nil) {
        self.isEditMode = alarm != nil
        
        if let existingAlarm = alarm {
            self.alarm = existingAlarm
        } else {
            // 기본 알람 설정
            let calendar = Calendar.current
            var dateComponents = calendar.dateComponents([.year, .month, .day], from: Date())
            dateComponents.hour = 8
            dateComponents.minute = 0
            
            self.alarm = Alarm(
                title: "알람",
                time: calendar.date(from: dateComponents) ?? Date(),
                days: [],
                isActive: true,
                sound: "Default",
                vibration: true,
                snooze: true,
                color: UIColor(red: 0.4, green: 0.6, blue: 1.0, alpha: 1.0)
            )
        }
    }
    
    // MARK: - Public Methods
    func updateTitle(_ title: String) {
        alarm.title = title
    }
    
    func updateTime(_ time: Date) {
        alarm.time = time
    }
    
    func updateDays(_ days: [WeekDay]) {
        alarm.days = days
    }
    
    func updateColor(_ color: UIColor) {
        alarm.color = color
    }
    
    func toggleActive() {
        alarm.isActive = !alarm.isActive
    }
    
    func updateSound(_ sound: String) {
        alarm.sound = sound
    }
    
    func updateVibration(_ isEnabled: Bool) {
        alarm.vibration = isEnabled
    }
    
    func updateSnooze(_ isEnabled: Bool) {
        alarm.snooze = isEnabled
    }
    
    func saveAlarm() {
        // 알람 유효성 검사
        guard !alarm.title.isEmpty else {
            errorBinding?("알람 제목을 입력해주세요.")
            return
        }
        
        // 시간 로그를 현지 시간 형식으로 출력
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.timeZone = TimeZone.current
        let localTimeString = formatter.string(from: alarm.time)
        
        print("알람 저장 (현지 시간): \(localTimeString)")
        print("알람 저장 (UTC): \(alarm.time)")
        
        alarmSavedHandler?(alarm)
    }
    
    func deleteAlarm() {
        guard isEditMode else {
            errorBinding?("새 알람은 삭제할 수 없습니다.")
            return
        }
        
        alarmDeletedHandler?()
    }
}
