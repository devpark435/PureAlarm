//
//  AlarmListViewModel.swift
//  PureAlarm
//
//  Created by 박현렬 on 2/27/25.
//

import Foundation
import UIKit

final class AlarmListViewModel {
    // MARK: - Properties
    private let useCase: AlarmUseCaseProtocol?
    private(set) var alarms: [Alarm] = []
    var alarmsBinding: (([Alarm]) -> Void)?
    var loadingBinding: ((Bool) -> Void)?
    var errorBinding: ((String) -> Void)?
    
    // MARK: - Initialization
    init(useCase: AlarmUseCaseProtocol? = nil) {
        self.useCase = useCase
        
        // 유스케이스가 없으면 더미 데이터 사용
        if useCase == nil {
            setupDummyData()
        }
    }
    
    // MARK: - Public Methods
    func fetchAlarms() {
        loadingBinding?(true)
        
        if let useCase = useCase {
            // 실제 유스케이스에서 데이터 가져오기
            alarms = useCase.getAlarms().sorted { $0.time < $1.time }
        }
        
        loadingBinding?(false)
        alarmsBinding?(alarms)
    }
    
    func addAlarm(_ alarm: Alarm) {
        if let useCase = useCase {
            useCase.saveAlarm(alarm)
            fetchAlarms()
        } else {
            alarms.append(alarm)
            alarmsBinding?(alarms)
        }
        
        // 알림 예약 - 실제 알림 등록
        scheduleAlarmNotification(alarm)
    }
    
    func updateAlarm(_ alarm: Alarm) {
        if let index = alarms.firstIndex(where: { $0.id == alarm.id }) {
            if let useCase = useCase {
                useCase.updateAlarm(alarm)
                fetchAlarms()
            } else {
                alarms[index] = alarm
                alarmsBinding?(alarms)
            }
            
            // 기존 알림 취소 후 다시 예약
            cancelAlarmNotification(alarm.id)
            if alarm.isActive {
                scheduleAlarmNotification(alarm)
            }
        } else {
            errorBinding?("알람을 찾을 수 없습니다.")
        }
    }
    
    func deleteAlarm(at index: Int) {
        guard index < alarms.count else {
            errorBinding?("알람을 찾을 수 없습니다.")
            return
        }
        
        let alarm = alarms[index]
        
        if let useCase = useCase {
            useCase.deleteAlarm(withId: alarm.id)
            fetchAlarms()
        } else {
            alarms.remove(at: index)
            alarmsBinding?(alarms)
        }
        
        // 알림 취소
        cancelAlarmNotification(alarm.id)
    }
    
    func toggleAlarm(at index: Int) {
        guard index < alarms.count else {
            errorBinding?("알람을 찾을 수 없습니다.")
            return
        }
        
        let alarm = alarms[index]
        var updatedAlarm = alarm
        updatedAlarm.isActive = !alarm.isActive
        
        if let useCase = useCase {
            useCase.setAlarmActive(withId: alarm.id, isActive: updatedAlarm.isActive)
            fetchAlarms()
        } else {
            alarms[index].isActive = updatedAlarm.isActive
            alarmsBinding?(alarms)
        }
        
        // 알림 상태 업데이트
        if updatedAlarm.isActive {
            scheduleAlarmNotification(updatedAlarm)
        } else {
            cancelAlarmNotification(alarm.id)
        }
    }
    
    // ID로 알람 토글 (셀 재사용 문제 해결을 위한 메서드)
    func toggleAlarmWithId(_ id: UUID, isActive: Bool) {
        if let index = alarms.firstIndex(where: { $0.id == id }) {
            var updatedAlarm = alarms[index]
            updatedAlarm.isActive = isActive
            
            if let useCase = useCase {
                useCase.setAlarmActive(withId: id, isActive: isActive)
                fetchAlarms()
            } else {
                alarms[index].isActive = isActive
                alarmsBinding?(alarms)
            }
            
            // 알림 상태 업데이트
            if isActive {
                scheduleAlarmNotification(updatedAlarm)
            } else {
                cancelAlarmNotification(id)
            }
        } else {
            errorBinding?("알람을 찾을 수 없습니다.")
        }
    }
    
    // 알람 ID로 알람 가져오기
    func getAlarm(at index: Int) -> Alarm? {
        guard index < alarms.count else { return nil }
        return alarms[index]
    }
    
    // MARK: - Private Methods
    private func setupDummyData() {
        // 임시 데이터로 테스트
        let calendar = Calendar.current
        var dateComponents = DateComponents()
        dateComponents.hour = 7
        dateComponents.minute = 30
        
        let morningAlarm = Alarm(
            title: "기상 시간",
            time: calendar.date(from: dateComponents) ?? Date(),
            days: [.monday, .tuesday, .wednesday, .thursday, .friday],
            color: UIColor(red: 0.4, green: 0.6, blue: 1.0, alpha: 1.0)
        )
        
        dateComponents.hour = 22
        dateComponents.minute = 30
        
        let nightAlarm = Alarm(
            title: "취침 준비",
            time: calendar.date(from: dateComponents) ?? Date(),
            days: [.monday, .tuesday, .wednesday, .thursday, .friday, .saturday, .sunday],
            color: UIColor(red: 0.6, green: 0.2, blue: 0.8, alpha: 1.0)
        )
        
        dateComponents.hour = 9
        dateComponents.minute = 0
        
        let weekendAlarm = Alarm(
            title: "주말 기상",
            time: calendar.date(from: dateComponents) ?? Date(),
            days: [.saturday, .sunday],
            color: UIColor(red: 1.0, green: 0.5, blue: 0.3, alpha: 1.0)
        )
        
        alarms = [morningAlarm, nightAlarm, weekendAlarm]
    }
    
    // 알림 예약
    private func scheduleAlarmNotification(_ alarm: Alarm) {
        AlarmNotificationManager.shared.scheduleAlarm(alarm: alarm) { success in
            if !success {
                self.errorBinding?("알람 예약에 실패했습니다.")
            } else {
                print("알람 예약 성공: \(alarm.title), 시간: \(alarm.time)")
            }
        }
    }
    
    // 알림 취소
    private func cancelAlarmNotification(_ alarmId: UUID) {
        AlarmNotificationManager.shared.cancelAlarm(alarmId: alarmId)
        print("알람 취소됨: \(alarmId)")
    }
}
