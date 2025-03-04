//
//  AlarmRepositoryProtocol.swift
//  PureAlarm
//
//  Created by 박현렬 on 2/28/25.
//

import Foundation

protocol AlarmRepositoryProtocol {
    func getAlarms() -> [Alarm]
    func saveAlarm(_ alarm: Alarm)
    func updateAlarm(_ alarm: Alarm)
    func deleteAlarm(withId id: UUID)
    func getAlarm(withId id: UUID) -> Alarm?
}
