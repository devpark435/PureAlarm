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
    
    /// 간단한 테스트 알람 생성 (5초 후에 알림)
    func scheduleTestAlarm() {
        print("테스트 알람 예약 시작...")
        
        // 현재 시간 문자열 미리 생성
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        let timeString = formatter.string(from: Date())
        
        let content = UNMutableNotificationContent()
        content.title = "테스트 알람"
        content.body = "이것은 테스트 알람입니다. 시간: " + timeString
        content.sound = UNNotificationSound.default
        
        // 5초 후에 알림 트리거
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(identifier: "test-alarm-" + UUID().uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("테스트 알람 등록 오류: \(error.localizedDescription)")
            } else {
                print("테스트 알람 성공적으로 등록됨 - 5초 후 알림 예정")
            }
        }
    }
    
    /// 알람 예약
    func scheduleAlarm(alarm: Alarm, completion: @escaping (Bool) -> Void) {
        // 알람이 활성화되어 있지 않으면 예약하지 않음
        guard alarm.isActive else {
            completion(false)
            return
        }
        
        print("알람 예약 시작: \(alarm.title)")
        
        // 기존 알람 관련 알림들 동기적으로 취소
        cancelAlarmSynchronously(alarmId: alarm.id) {
            // 취소 완료 후 새 알람 생성
            self.createNewAlarmBatch(for: alarm, completion: completion)
        }
    }
    
    // 동기적으로 알람 취소하는 메서드 추가
    func cancelAlarmSynchronously(alarmId: UUID, completion: @escaping () -> Void) {
        print("알람 동기적 취소 시작: \(alarmId)")
        
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let identifiersToRemove = requests
                .filter { $0.identifier.contains(alarmId.uuidString) }
                .map { $0.identifier }
            
            if !identifiersToRemove.isEmpty {
                UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiersToRemove)
                print("\(identifiersToRemove.count)개 알림 취소 완료")
            } else {
                print("취소할 알림 없음")
            }
            
            DispatchQueue.main.async {
                completion()
            }
        }
    }
    
    /// 알람 취소
    func cancelAlarm(alarmId: UUID) {
        print("알람 취소 요청: \(alarmId)")
        
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let identifiersToRemove = requests
                .filter { $0.identifier.contains(alarmId.uuidString) }
                .map { $0.identifier }
            
            if !identifiersToRemove.isEmpty {
                UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiersToRemove)
                print("\(identifiersToRemove.count)개의 관련 알림 취소됨")
            } else {
                print("취소할 알림이 없음")
            }
        }
    }
    
    /// 모든 알람 취소
    func cancelAllAlarms() {
        print("모든 알람 취소 요청")
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    /// 스누즈 알람 설정
    func scheduleSnoozeAlarm(for alarmId: UUID, minutes: Int = 5) {
        print("스누즈 알람 요청: \(alarmId), \(minutes)분 후")
        
        // 기존 알람 정보 가져오기
        guard let alarm = getAlarmById(alarmId) else {
            print("알람 정보를 찾을 수 없음")
            return
        }
        
        // 기존 알람 관련 알림 모두 취소
        cancelAlarmSynchronously(alarmId: alarmId) {
            // 스누즈 시간 계산 (현재 시간 + minutes분)
            let snoozeDate = Date().addingTimeInterval(TimeInterval(minutes * 60))
            
            // 스누즈된 알람 객체 생성
            var snoozeAlarm = alarm
            snoozeAlarm.time = snoozeDate
            snoozeAlarm.title = "\(alarm.title) (스누즈)"
            
            // 스누즈 알람 예약
            self.scheduleAlarm(alarm: snoozeAlarm) { success in
                if success {
                    print("스누즈 알람 설정 완료: \(minutes)분 후 (시간: \(self.formatTime(date: snoozeDate)))")
                } else {
                    print("스누즈 알람 설정 실패")
                }
            }
        }
    }
    
    // 알람 ID로 알람 정보 가져오기
    internal func getAlarmById(_ alarmId: UUID) -> Alarm? {
        // 실제 저장소에서 알람 정보 가져오기 (가능한 경우)
        if let alarms = try? AlarmStorage.shared.loadAlarms(),
           let alarm = alarms.first(where: { $0.id == alarmId }) {
            return alarm
        }
        
        // 저장소에서 찾지 못한 경우 임시 데이터 반환
        print("저장소에서 알람을 찾지 못함, 임시 알람 생성: \(alarmId)")
        let dummyAlarm = Alarm(
            id: alarmId,
            title: "알람",
            time: Date(),
            isActive: true
        )
        return dummyAlarm
    }
    
    // MARK: - Private Methods
    
    // 새로운 알람 배치 생성 메서드
    private func createNewAlarmBatch(for alarm: Alarm, completion: @escaping (Bool) -> Void) {
        let alarmDate = getValidAlarmTime(for: alarm)
        print("알람 시간 계산됨: \(formatTime(date: alarmDate))")
        
        // 알림 생성 (첫 알람 포함 총 6개)
        let alarmCount = 6
        
        // 알람 상태 추적용 카운터
        var successCount = 0
        var failureCount = 0
        let group = DispatchGroup()
        
        for i in 0..<alarmCount {
            group.enter()
            
            // 알림 내용 설정
            let content = UNMutableNotificationContent()
            
            if i == 0 {
                // 첫 번째 알람
                content.title = "⏰ 알람 시간"
                content.body = "알람이 울렸습니다!"
            } else {
                // 후속 알람
                content.title = "\(alarm.title.isEmpty ? "알람" : alarm.title) (반복 \(i))"
                content.body = "놓친 알람이 있습니다!"
            }
            
            // 공통 설정
            content.sound = UNNotificationSound.default
            content.categoryIdentifier = "ALARM_CATEGORY"
            content.userInfo = [
                "alarm_id": alarm.id.uuidString,
                "sequence": i,
                "timestamp": Date().timeIntervalSince1970
            ]
            
            // 알람 시간 계산 (i=0은 원래 시간, 나머지는 2초 간격)
            var triggerDate = alarmDate
            if i > 0 {
                triggerDate = Calendar.current.date(byAdding: .second, value: i * 2, to: alarmDate) ?? alarmDate
            }
            
            // 트리거 생성
            let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: triggerDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            
            // 고유 식별자 생성
            let timestamp = Int(Date().timeIntervalSince1970 * 1000)
            let requestId = i == 0
                ? "\(alarm.id.uuidString)-main-\(timestamp)"
                : "\(alarm.id.uuidString)-follow-\(i)-\(timestamp)"
            
            let request = UNNotificationRequest(identifier: requestId, content: content, trigger: trigger)
            
            // 알림 등록
            UNUserNotificationCenter.current().add(request) { error in
                defer { group.leave() }
                
                if let error = error {
                    print("알림 \(i) 등록 오류: \(error.localizedDescription)")
                    failureCount += 1
                } else {
                    print("알림 \(i) 등록 성공: \(self.formatTime(date: triggerDate))")
                    successCount += 1
                }
            }
        }
        
        // 모든 알림 등록 완료 후 결과 반환
        group.notify(queue: .main) {
            let success = failureCount == 0 && successCount > 0
            print("알람 등록 완료 - 성공: \(successCount), 실패: \(failureCount)")
            completion(success)
        }
    }
    
    /// 주간 반복 알람 예약
    private func scheduleRepeatingAlarm(alarm: Alarm, completion: @escaping (Bool) -> Void) {
        var allSuccess = true
        let group = DispatchGroup()
        
        // 각 요일별로 알람 설정
        for day in alarm.days {
            group.enter()
            
            let content = UNMutableNotificationContent()
            content.title = alarm.title.isEmpty ? "알람" : alarm.title
            content.body = "반복 알람이 울렸습니다!"
            content.sound = UNNotificationSound.default
            content.userInfo = ["alarm_id": alarm.id.uuidString]
            content.categoryIdentifier = "ALARM_CATEGORY"
            
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
    
    /// 유효한 알람 시간 가져오기 (항상 현재 이후의 시간)
    private func getValidAlarmTime(for alarm: Alarm) -> Date {
        let calendar = Calendar.current
        var alarmDate = alarm.time
        
        // 일회성 알람의 경우
        if alarm.days.isEmpty {
            // 오늘 날짜에 알람 시간 설정
            alarmDate = combineDateAndTime(Date(), alarm.time)
            
            // 이미 지난 시간이면 최소 10초 후로 설정 (테스트 목적)
            if alarmDate < Date() {
                // 실제 앱에서는 다음 날로 설정하겠지만, 테스트를 위해 10초 후로 설정
                alarmDate = Date().addingTimeInterval(10)
                print("지난 시간 알람이 감지됨, 테스트를 위해 10초 후로 설정: \(formatTime(date: alarmDate))")
            }
        }
        
        return alarmDate
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
            print("알람 중지 액션 - 모든 관련 알림 철저히 취소")
            
            // 즉시 기존 알림 취소 시도
            AlarmNotificationManager.shared.cancelAlarm(alarmId: alarmId)
            
            // 동기적 취소 추가 실행 (이중 보호)
            AlarmNotificationManager.shared.cancelAlarmSynchronously(alarmId: alarmId) {
                print("알람 \(alarmId) 최종 취소 완료")
                
                // 추가 보호: 1초 후 다시 한 번 취소 명령 실행
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    UNUserNotificationCenter.current().removeAllDeliveredNotifications()
                    print("모든 전달된 알림 제거 완료")
                }
            }
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
