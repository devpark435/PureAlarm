//
//  AlarmStorage.swift
//  PureAlarm
//
//  Created by 박현렬 on 2/28/25.
//

import Foundation
import UIKit

final class AlarmStorage {
    static let shared = AlarmStorage()
    
    private let alarmsKey = "savedAlarms"
    private let firstLaunchKey = "isFirstLaunch"
    
    private init() {
        setupDefaultAlarmsIfNeeded()
    }
    
    private func setupDefaultAlarmsIfNeeded() {
        // 앱 첫 실행 여부 확인
        let isFirstLaunch = !UserDefaults.standard.bool(forKey: firstLaunchKey)
        
        if isFirstLaunch {
            // 기존 데이터 초기화 (모델 변경 문제 해결)
            UserDefaults.standard.removeObject(forKey: alarmsKey)
            
            // 기본 알람 데이터 생성 및 저장
            let defaultAlarms = createDefaultAlarms()
            saveAlarms(defaultAlarms)
            
            // 첫 실행 표시 저장
            UserDefaults.standard.set(true, forKey: firstLaunchKey)
            print("기본 알람이 설정되었습니다.")
        }
    }
    
    private func createDefaultAlarms() -> [Alarm] {
        let calendar = Calendar.current
        var dateComponents = DateComponents()
        
        // 기상 알람
        dateComponents.hour = 7
        dateComponents.minute = 30
        let morningAlarm = Alarm(
            title: "기상 시간",
            time: calendar.date(from: dateComponents) ?? Date(),
            days: [.monday, .tuesday, .wednesday, .thursday, .friday],
            isActive: true,
            sound: "Default",
            vibration: true,
            snooze: true,
            repeatInterval: 5, // 5분마다 반복
            color: UIColor(red: 0.4, green: 0.6, blue: 1.0, alpha: 1.0)
        )
        
        // 취침 알람
        dateComponents.hour = 22
        dateComponents.minute = 30
        let nightAlarm = Alarm(
            title: "취침 준비",
            time: calendar.date(from: dateComponents) ?? Date(),
            days: [.monday, .tuesday, .wednesday, .thursday, .friday, .saturday, .sunday],
            isActive: true,
            sound: "Default",
            vibration: true,
            snooze: true,
            repeatInterval: 0, // 반복 없음
            color: UIColor(red: 0.6, green: 0.2, blue: 0.8, alpha: 1.0)
        )
        
        // 주말 알람
        dateComponents.hour = 9
        dateComponents.minute = 0
        let weekendAlarm = Alarm(
            title: "주말 기상",
            time: calendar.date(from: dateComponents) ?? Date(),
            days: [.saturday, .sunday],
            isActive: true,
            sound: "Default",
            vibration: true,
            snooze: true,
            repeatInterval: 10, // 10분마다 반복
            color: UIColor(red: 1.0, green: 0.5, blue: 0.3, alpha: 1.0)
        )
        
        return [morningAlarm, nightAlarm, weekendAlarm]
    }
    
    // 기존 메소드들...
    func saveAlarm(_ alarm: Alarm) {
        var alarms = loadAlarms()
        
        if let index = alarms.firstIndex(where: { $0.id == alarm.id }) {
            alarms[index] = alarm
        } else {
            alarms.append(alarm)
        }
        
        saveAlarms(alarms)
    }
    
    func saveAlarms(_ alarms: [Alarm]) {
        do {
            let data = try JSONEncoder().encode(alarms)
            UserDefaults.standard.set(data, forKey: alarmsKey)
        } catch {
            print("알람 저장 실패: \(error.localizedDescription)")
        }
    }
    
    func loadAlarms() -> [Alarm] {
        guard let data = UserDefaults.standard.data(forKey: alarmsKey) else {
            return []
        }
        
        do {
            return try JSONDecoder().decode([Alarm].self, from: data)
        } catch {
            print("알람 불러오기 실패: \(error.localizedDescription)")
            return []
        }
    }
    
    func deleteAlarm(withId id: UUID) {
        var alarms = loadAlarms()
        alarms.removeAll { $0.id == id }
        saveAlarms(alarms)
    }
    
    // UserDefaults 리셋 메소드 (필요할 때 한 번 호출)
    func resetAllData() {
        UserDefaults.standard.removeObject(forKey: alarmsKey)
        UserDefaults.standard.removeObject(forKey: firstLaunchKey)
        print("모든 알람 데이터가 초기화되었습니다.")
    }
}
