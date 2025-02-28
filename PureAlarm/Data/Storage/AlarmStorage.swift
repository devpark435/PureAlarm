//
//  AlarmStorage.swift
//  PureAlarm
//
//  Created by 박현렬 on 2/28/25.
//

import Foundation

final class AlarmStorage {
    static let shared = AlarmStorage()
    
    private let alarmsKey = "savedAlarms"
    
    private init() {}
    
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
}
