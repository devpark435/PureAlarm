//
//  AlarmNotificationManager.swift
//  PureAlarm
//
//  Created by 박현렬 on 2/27/25.
//

import Foundation
import UserNotifications
import UIKit

class AlarmNotificationManager {
    static let shared = AlarmNotificationManager()
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// 알림 권한 요청
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("알림 권한 요청 오류: \(error.localizedDescription)")
                completion(false)
                return
            }
            completion(granted)
        }
    }
    
    /// 알람 예약
    func scheduleAlarm(alarm: Alarm, completion: @escaping (Bool) -> Void) {
        // 알람이 활성화되어 있지 않으면 예약하지 않음
        guard alarm.isActive else {
            completion(false)
            return
        }
        
        // 알람 내용 생성
        let content = UNMutableNotificationContent()
        content.title = alarm.title.isEmpty ? "알람" : alarm.title
        content.body = "지금 시간: \(formatTime(date: Date()))"
        content.sound = UNNotificationSound.default // 기본 소리로 설정 (실제로는 커스텀 소리 사용)
        content.userInfo = ["alarm_id": alarm.id.uuidString] // 알람 ID 저장
        content.categoryIdentifier = "ALARM_CATEGORY" // 카테고리 지정 추가
        
        // 알람이 반복되는 경우
        if !alarm.days.isEmpty {
            scheduleRepeatingAlarm(alarm: alarm, content: content, completion: completion)
        } else {
            scheduleOneTimeAlarm(alarm: alarm, content: content, completion: completion)
        }
    }
    
    /// 알람 취소
    func cancelAlarm(alarmId: UUID) {
        if let identifiers = getNotificationIdentifiers(for: alarmId) {
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
        }
    }
    
    /// 모든 알람 취소
    func cancelAllAlarms() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    /// 스누즈 알람 설정
    func scheduleSnoozeAlarm(for alarmId: UUID, minutes: Int = 5) {
        // 기존 알람 정보 가져오기
        guard let alarm = getAlarmById(alarmId) else { return }
        
        // 알람 내용 생성
        let content = UNMutableNotificationContent()
        content.title = "\(alarm.title) (스누즈)"
        content.body = "지금 시간: \(formatTime(date: Date()))"
        content.sound = UNNotificationSound.default
        content.userInfo = ["alarm_id": alarm.id.uuidString, "is_snooze": true]
        content.categoryIdentifier = "ALARM_CATEGORY" // 카테고리 지정 추가
        
        // 스누즈 시간 계산 (현재 시간 + minutes분)
        let calendar = Calendar.current
        
        guard let triggerDate = calendar.date(byAdding: .minute, value: minutes, to: Date()) else {
            print("스누즈 시간 계산 오류")
            return
        }
        
        // 알림 트리거 생성 (현지 시간대 고려)
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        // 스누즈 알람 ID 생성
        let requestId = "\(alarm.id.uuidString)-snooze"
        
        // 알림 요청 생성 및 등록
        let request = UNNotificationRequest(identifier: requestId, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("스누즈 알람 설정 오류: \(error.localizedDescription)")
            } else {
                print("스누즈 알람 설정 완료: \(minutes)분 후 (현지 시간: \(triggerDate))")
            }
        }
    }
    
    // 알람 ID로 알람 정보 가져오기 (internal로 변경)
    internal func getAlarmById(_ alarmId: UUID) -> Alarm? {
        // 실제 구현에서는 저장소에서 알람 정보를 가져와야 함
        // 여기서는 임시로 더미 데이터 반환
        let dummyAlarm = Alarm(
            id: alarmId,
            title: "알람",
            time: Date(),
            isActive: true
        )
        return dummyAlarm
    }
    
    // MARK: - Private Methods
    
    /// 일회성 알람 예약
    private func scheduleOneTimeAlarm(alarm: Alarm, content: UNMutableNotificationContent, completion: @escaping (Bool) -> Void) {
        // 현재 시간과 비교하여 알람 시간이 지났으면 다음 날로 설정
        var alarmDate = combineDateAndTime(Date(), alarm.time)
        if alarmDate < Date() {
            if let nextDay = Calendar.current.date(byAdding: .day, value: 1, to: Date()) {
                alarmDate = combineDateAndTime(nextDay, alarm.time)
            }
        }
        
        // 알람 시간 컴포넌트 추출
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: alarmDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        // 알림 요청 생성
        let requestId = alarm.id.uuidString
        let request = UNNotificationRequest(identifier: requestId, content: content, trigger: trigger)
        
        // 알림 등록
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("알람 등록 오류: \(error.localizedDescription)")
                completion(false)
                return
            }
            print("알람 등록 성공: \(alarmDate)")
            completion(true)
        }
    }
    
    /// 반복 알람 예약
    private func scheduleRepeatingAlarm(alarm: Alarm, content: UNMutableNotificationContent, completion: @escaping (Bool) -> Void) {
        var allSuccess = true
        let group = DispatchGroup()
        
        // 각 요일별로 알람 설정
        for day in alarm.days {
            group.enter()
            
            // 요일별 알람 시간 컴포넌트 생성
            var components = Calendar.current.dateComponents([.hour, .minute], from: alarm.time)
            components.weekday = day.rawValue
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            
            // 요일별 고유 식별자 생성
            let requestId = "\(alarm.id.uuidString)-\(day.rawValue)"
            
            // 알림 요청 생성
            let request = UNNotificationRequest(identifier: requestId, content: content, trigger: trigger)
            
            // 알림 등록
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("반복 알람 등록 오류 (\(day.shortName)): \(error.localizedDescription)")
                    allSuccess = false
                } else {
                    print("반복 알람 등록 성공 (\(day.shortName)): \(components)")
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            completion(allSuccess)
        }
    }
    
    /// 날짜와 시간 결합하기
    private func combineDateAndTime(_ date: Date, _ time: Date) -> Date {
        let calendar = Calendar.current
        
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        let timeComponents = calendar.dateComponents([.hour, .minute, .second], from: time)
        
        var combinedComponents = DateComponents()
        combinedComponents.year = dateComponents.year
        combinedComponents.month = dateComponents.month
        combinedComponents.day = dateComponents.day
        combinedComponents.hour = timeComponents.hour
        combinedComponents.minute = timeComponents.minute
        combinedComponents.second = timeComponents.second
        
        return calendar.date(from: combinedComponents) ?? date
    }
    
    /// 시간 포맷팅
    private func formatTime(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    /// 알람 ID로 알림 식별자 목록 가져오기
    private func getNotificationIdentifiers(for alarmId: UUID) -> [String]? {
        let idString = alarmId.uuidString
        var identifiers = [idString] // 기본 ID
        
        // 반복 알람의 경우 요일별 ID 추가
        for day in WeekDay.allCases {
            identifiers.append("\(idString)-\(day.rawValue)")
        }
        
        // 스누즈 ID 추가
        identifiers.append("\(idString)-snooze")
        
        return identifiers
    }
}

// MARK: - 알람 알림 핸들러
extension AppDelegate: UNUserNotificationCenterDelegate {
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // 앱 실행 중에도 알림 표시
        if #available(iOS 14.0, *) {
            completionHandler([.banner, .sound])
        } else {
            completionHandler([.alert, .sound])
        }
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        
        // 디버그 로그 추가
        print("알림 응답 받음: \(userInfo)")
        
        // 알람 ID 추출
        guard let alarmIdString = userInfo["alarm_id"] as? String,
              let alarmId = UUID(uuidString: alarmIdString) else {
            print("알람 ID 추출 실패")
            completionHandler()
            return
        }
        
        print("알람 ID 추출 성공: \(alarmId)")
        
        // 응답 액션에 따라 처리
        switch response.actionIdentifier {
        case UNNotificationDefaultActionIdentifier:
            // 기본 액션: 알람 화면 표시
            print("기본 액션: 알람 화면 표시 시도")
            showAlarmScreen(for: alarmId)
            
        case UNNotificationDismissActionIdentifier:
            // 알림 무시: 아무 작업 없음
            print("알림 무시됨")
            break
            
        case "SNOOZE_ACTION":
            // 스누즈 액션
            print("스누즈 액션 실행")
            AlarmNotificationManager.shared.scheduleSnoozeAlarm(for: alarmId)
            
        case "STOP_ACTION":
            // 알람 중지 액션
            print("알람 중지 액션")
            break
            
        default:
            print("알 수 없는 액션: \(response.actionIdentifier)")
            break
        }
        
        completionHandler()
    }
    
    private func showAlarmScreen(for alarmId: UUID) {
        print("showAlarmScreen 메서드 호출됨: \(alarmId)")
        
        // 알람 ID로 알람 정보 가져오기
        guard let alarm = AlarmNotificationManager.shared.getAlarmById(alarmId) else {
            print("알람 정보 가져오기 실패: \(alarmId)")
            return
        }
        
        print("알람 정보 가져오기 성공: \(alarm.title)")
        
        // 메인 스레드에서 실행
        DispatchQueue.main.async {
                let alarmRingVC = AlarmRingViewController(alarm: alarm)
                alarmRingVC.modalPresentationStyle = .fullScreen
                
                guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
                    print("새로운 윈도우 생성 실패")
                    return
                }
                
                self.alarmWindow = UIWindow(windowScene: scene)
                self.alarmWindow?.rootViewController = alarmRingVC
                self.alarmWindow?.makeKeyAndVisible()
                
                print("새로운 윈도우에서 알람 화면 표시 완료")
            }
    }
}

// MARK: - AppDelegate 설정
extension AppDelegate {
    func setupNotifications() {
        // 알림 대리자 설정
        UNUserNotificationCenter.current().delegate = self
        
        // 알림 권한 요청
        AlarmNotificationManager.shared.requestAuthorization { granted in
            if granted {
                print("알림 권한 허용됨")
            } else {
                print("알림 권한 거부됨")
            }
        }
        
        // 알림 카테고리 및 액션 등록
        registerNotificationCategories()
    }
    
    private func registerNotificationCategories() {
        // 스누즈 액션
        let snoozeAction = UNNotificationAction(
            identifier: "SNOOZE_ACTION",
            title: "5분 후 다시 알림",
            options: .foreground
        )
        
        // 알람 중지 액션
        let stopAction = UNNotificationAction(
            identifier: "STOP_ACTION",
            title: "알람 끄기",
            options: [.destructive, .foreground]  // .foreground 옵션 추가
        )
        
        // 알람 카테고리 생성
        let alarmCategory = UNNotificationCategory(
            identifier: "ALARM_CATEGORY",
            actions: [snoozeAction, stopAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        
        // 카테고리 등록
        UNUserNotificationCenter.current().setNotificationCategories([alarmCategory])
    }
}
