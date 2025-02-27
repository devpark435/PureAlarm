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
    private var alarms: [Alarm] = []
    
    // MARK: - Outputs
    var alarmsBinding: (([Alarm]) -> Void)?
    var loadingBinding: ((Bool) -> Void)?
    var errorBinding: ((String) -> Void)?
    
    // MARK: - Initialization
    init() {
        setupDummyData()
    }
    
    // MARK: - Public Methods
    func fetchAlarms() {
        loadingBinding?(true)
        
        // 현재는 더미 데이터로 대체
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            guard let self = self else { return }
            self.loadingBinding?(false)
            self.alarmsBinding?(self.alarms)
        }
    }
    
    func getAlarm(at index: Int) -> Alarm? {
        guard index < alarms.count else { return nil }
        return alarms[index]
    }
    
    func addAlarm(_ alarm: Alarm) {
        alarms.append(alarm)
        alarmsBinding?(alarms)
    }
    
    func updateAlarm(_ alarm: Alarm) {
        if let index = alarms.firstIndex(where: { $0.id == alarm.id }) {
            alarms[index] = alarm
            alarmsBinding?(alarms)
        } else {
            errorBinding?("알람을 찾을 수 없습니다.")
        }
    }
    
    func deleteAlarm(at index: Int) {
        guard index < alarms.count else {
            errorBinding?("알람을 찾을 수 없습니다.")
            return
        }
        
        alarms.remove(at: index)
        alarmsBinding?(alarms)
    }
    
    func toggleAlarm(at index: Int) {
        guard index < alarms.count else {
            errorBinding?("알람을 찾을 수 없습니다.")
            return
        }
        
        alarms[index].isActive = !alarms[index].isActive
        alarmsBinding?(alarms)
    }
    
    func toggleAlarmWithId(_ id: UUID, isActive: Bool) {
        if let index = alarms.firstIndex(where: { $0.id == id }) {
            alarms[index].isActive = isActive
            alarmsBinding?(alarms)
        }
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
}
