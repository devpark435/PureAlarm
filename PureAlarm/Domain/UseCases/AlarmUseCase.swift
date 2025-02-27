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
