//
//  AlarmUseCase.swift
//  PureAlarm
//
//  Created by 박현렬 on 2/26/25.
//

import Foundation

protocol AlarmUseCaseProtocol {
    func getAlarms() -> [Alarm]
    func saveAlarm(_ alarm: Alarm)
    func updateAlarm(_ alarm: Alarm)
    func deleteAlarm(withId id: UUID)
    func setAlarmActive(withId id: UUID, isActive: Bool)
}

final class AlarmUseCase: AlarmUseCaseProtocol {
    private let repository: AlarmRepositoryProtocol
    private let notificationManager: AlarmNotificationManager
    
    init(repository: AlarmRepositoryProtocol, notificationManager: AlarmNotificationManager = .shared) {
        self.repository = repository
        self.notificationManager = notificationManager
    }
    
    func getAlarms() -> [Alarm] {
        return repository.getAlarms()
    }
    
    func saveAlarm(_ alarm: Alarm) {
        repository.saveAlarm(alarm)
        if alarm.isActive {
            scheduleAlarmNotification(alarm)
        }
    }
    
    func updateAlarm(_ alarm: Alarm) {
        repository.updateAlarm(alarm)
        
        // 기존 알림 취소 후 다시 예약
        notificationManager.cancelAlarm(alarmId: alarm.id)
        if alarm.isActive {
            scheduleAlarmNotification(alarm)
        }
    }
    
    func deleteAlarm(withId id: UUID) {
        repository.deleteAlarm(withId: id)
        notificationManager.cancelAlarm(alarmId: id)
    }
    
    func setAlarmActive(withId id: UUID, isActive: Bool) {
        if let alarm = repository.getAlarm(withId: id) {
            var updatedAlarm = alarm
            updatedAlarm.isActive = isActive
            repository.updateAlarm(updatedAlarm)
            
            if isActive {
                scheduleAlarmNotification(updatedAlarm)
            } else {
                notificationManager.cancelAlarm(alarmId: id)
            }
        }
    }
    
    // 알림 스케줄링
    private func scheduleAlarmNotification(_ alarm: Alarm) {
        notificationManager.scheduleAlarm(alarm: alarm) { _ in }
    }
}
