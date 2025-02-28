//
//  File.swift
//  PureAlarm
//
//  Created by 박현렬 on 2/28/25.
//

import Foundation

final class AlarmRepository: AlarmRepositoryProtocol {
    private let storage: AlarmStorage
    
    init(storage: AlarmStorage = AlarmStorage.shared) {
        self.storage = storage
    }
    
    func getAlarms() -> [Alarm] {
        return storage.loadAlarms()
    }
    
    func saveAlarm(_ alarm: Alarm) {
        storage.saveAlarm(alarm)
    }
    
    func updateAlarm(_ alarm: Alarm) {
        storage.saveAlarm(alarm)
    }
    
    func deleteAlarm(withId id: UUID) {
        storage.deleteAlarm(withId: id)
    }
    
    func getAlarm(withId id: UUID) -> Alarm? {
        return storage.loadAlarms().first(where: { $0.id == id })
    }
}
