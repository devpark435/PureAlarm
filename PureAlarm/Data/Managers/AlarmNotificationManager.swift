//
//  AlarmNotificationManager.swift
//  PureAlarm
//
//  Created by 박현렬 on 2/27/25.
//

import Foundation
import UserNotifications
import UIKit
import AVFoundation

// 알람 예약 실패 이유를 나타내는 열거형
enum ScheduleFailureReason {
    case inactiveAlarm         // 비활성 알람
    case duplicateProcessing   // 중복 처리 중
    case notificationError     // 알림 등록 오류
    
    var description: String {
        switch self {
        case .inactiveAlarm: return "비활성 알람"
        case .duplicateProcessing: return "이미 처리 중인 알람"
        case .notificationError: return "알림 등록 오류"
        }
    }
}

// 알람 알림 유형 정의
enum AlarmNotificationType {
    case main               // 주요 알람 (첫 알람)
    case followUp(Int)      // 후속 알람 (sequence 번호 포함)
    case missed             // 놓친 알람
    case snooze             // 스누즈 알람
    case check              // 체크용 알람 (표시되지 않음)
}

class AlarmNotificationManager {
    static let shared = AlarmNotificationManager()
    
    // MARK: - Properties
    
    private var processingAlarms = Set<String>()
    private let processingQueue = DispatchQueue(label: "com.purealarm.notification.queue")
    
    // 오디오 관련 속성
    private var audioPlayer: AVAudioPlayer?
    private var isPlayingAlarmSound = false
    
    // 백그라운드 작업 식별자
    private var backgroundTaskID: UIBackgroundTaskIdentifier = .invalid
    
    // 시스템 사운드 타이머
    private var systemSoundTimer: Timer?
    
    // 스누즈 알람 ID 세트
    private var snoozeAlarmIds = Set<UUID>()
    
    // 알람 소리 자동 중지 타이머
    private var alarmSoundTimer: Timer?
    private let defaultAlarmDuration: TimeInterval = 60 // 1분
    
    // 반복 알람 중지를 위한 플래그 관리
    private var stoppedAlarmTimes = [UUID: Date]()
    
    private init() {}
    
    // MARK: - Public Interface
    
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
    
    /// 테스트 알람 생성 (5초 후에 알림)
    func scheduleTestAlarm() {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        let timeString = formatter.string(from: Date())
        
        let content = UNMutableNotificationContent()
        content.title = "테스트 알람"
        content.body = "이것은 테스트 알람입니다. 시간: " + timeString
        content.sound = UNNotificationSound.default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(identifier: "test-alarm-" + UUID().uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("테스트 알람 등록 오류: \(error.localizedDescription)")
            }
        }
    }
    
    /// 알람 소리 재생
    func playAlarmSound() {
        guard !isPlayingAlarmSound else { return }
        
        // 알람 소리 파일 경로 가져오기
        guard let soundURL = Bundle.main.url(forResource: "alarm_sound", withExtension: "mp3") else {
            // 번들에 소리 파일이 없는 경우 시스템 사운드 사용
            let systemSoundID: SystemSoundID = 1005 // 시스템 알람 소리
            AudioServicesPlaySystemSound(systemSoundID)
            startSystemSoundRepeatTimer()
            return
        }
        
        do {
            // 오디오 세션 설정
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            
            // 플레이어 생성 및 재생
            audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
            audioPlayer?.numberOfLoops = 0
            audioPlayer?.volume = 1.0
            audioPlayer?.play()
            isPlayingAlarmSound = true
            
            startAlarmSoundTimer()
        } catch {
            print("알람 소리 재생 오류: \(error.localizedDescription)")
            let systemSoundID: SystemSoundID = 1005
            AudioServicesPlaySystemSound(systemSoundID)
            startSystemSoundRepeatTimer()
        }
    }
    
    /// 알람 소리 중지
    func stopAlarmSound() {
        guard isPlayingAlarmSound else { return }
        
        // 오디오 플레이어 중지
        audioPlayer?.stop()
        audioPlayer = nil
        
        // 시스템 사운드 타이머 중지
        stopSystemSoundRepeatTimer()
        
        isPlayingAlarmSound = false
        
        // 오디오 세션 비활성화
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            print("오디오 세션 비활성화 오류: \(error.localizedDescription)")
        }
    }
    
    /// 알람 소리가 재생 중인지 확인
    func isAlarmSoundPlaying() -> Bool {
        return isPlayingAlarmSound
    }
    
    /// 알람 예약
    func scheduleAlarm(alarm: Alarm, completion: @escaping (Bool, ScheduleFailureReason?) -> Void) {
        // 알람이 활성화되어 있지 않으면 예약하지 않음
        guard alarm.isActive else {
            completion(false, .inactiveAlarm)
            return
        }
        
        // 알람 ID 문자열
        let alarmIdString = alarm.id.uuidString
        
        // 중복 호출 방지를 위한 처리
        var shouldProceed = false
        
        processingQueue.sync {
            if processingAlarms.contains(alarmIdString) {
                print("⚠️ 경고: 알람 \(alarmIdString)는 이미 처리 중입니다.")
            } else {
                processingAlarms.insert(alarmIdString)
                shouldProceed = true
            }
        }
        
        // 이미 처리 중인 알람이면 중단
        if !shouldProceed {
            DispatchQueue.main.async {
                completion(true, .duplicateProcessing)
            }
            return
        }
        
        // 중지 플래그 제거 (반복 허용)
        resetStopFlag(for: alarm.id)
        
        // 기존 알람 관련 알림들 취소 후 새 알람 생성
        cancelAlarmNotifications(alarmId: alarm.id) {
            self.createNewAlarmBatch(for: alarm) { success in
                // 완료 후 처리 중 표시 제거
                self.processingQueue.sync {
                    self.processingAlarms.remove(alarmIdString)
                }
                
                if !success {
                    completion(false, .notificationError)
                } else {
                    completion(true, nil)
                }
            }
        }
    }
    
    /// 알람 취소 - 중지 플래그 설정 및 알림 제거
    func cancelAlarm(alarmId: UUID) {
        // 알람 정보 가져오기
        guard let alarm = getAlarmById(alarmId) else {
            print("알람 취소 - 알람 정보를 찾을 수 없음: \(alarmId)")
            return
        }
        
        // 알람 소리 중지 및 자원 정리
        cleanupAlarmResources(alarmId: alarmId)
        
        // 전달된 알림 제거
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [alarmId.uuidString])
        
        // 알람 유형에 따라 처리
        if !alarm.days.isEmpty {
            cancelRepeatingAlarmForToday(alarmId: alarmId)
        } else {
            cancelNonRepeatingAlarm(alarmId: alarmId)
        }
    }
    
    /// 알람 알림만 취소 (중지 플래그 설정 없음)
    func cancelAlarmNotifications(alarmId: UUID, completion: @escaping () -> Void) {
        // 전달된 알림도 함께 취소
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [alarmId.uuidString])
        
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let identifiersToRemove = requests
                .filter { $0.identifier.contains(alarmId.uuidString) }
                .map { $0.identifier }
            
            if !identifiersToRemove.isEmpty {
                UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiersToRemove)
            }
            
            DispatchQueue.main.async {
                completion()
            }
        }
    }
    
    /// 모든 알람 취소
    func cancelAllAlarms() {
        // 알람 소리 중지
        stopAlarmSound()
        
        // 백그라운드 작업 종료
        endBackgroundTask()
        
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }
    
    /// 스누즈 알람 설정
    func scheduleSnoozeAlarm(for alarmId: UUID, minutes: Int) {
        // 기존 알람 정보 가져오기
        guard let originalAlarm = getAlarmById(alarmId) else {
            print("스누즈: 알람 정보를 찾을 수 없음, 스누즈 설정 불가: \(alarmId)")
            return
        }
        
        // 기존 알람 관련 알림 모두 취소 (중지 플래그는 설정하지 않음)
        cancelAlarmNotifications(alarmId: alarmId) {
            // 스누즈 시간 계산 (현재 시간 + minutes분)
            let snoozeDate = Date().addingTimeInterval(TimeInterval(minutes * 60))
            
            // 스누즈된 알람 객체 생성
            var snoozeAlarm = originalAlarm
            snoozeAlarm.time = snoozeDate
            snoozeAlarm.title = "\(originalAlarm.title) (스누즈)"
            
            // 스누즈 알람으로 표시
            self.safelyExecuteOnMainThread {
                self.snoozeAlarmIds.insert(snoozeAlarm.id)
            }
            
            // 중지 플래그 초기화 (새 알람이므로 이전 중지 상태를 무시)
            self.resetStopFlag(for: snoozeAlarm.id)
            
            // 스누즈 알람 예약 (원래 알람의 반복 간격 유지)
            self.scheduleAlarm(alarm: snoozeAlarm) { success, reason in
                if success {
                    // 스누즈 알람도 반복 타이머 설정
                    if snoozeAlarm.repeatInterval > 0 {
                        // 스누즈 알람이 울린 후 반복 타이머 설정 (30초 후에 체크)
                        let snoozeDelayInSeconds = TimeInterval(minutes * 60)
                        
                        // 특정 시간에 알람 반복 체크를 트리거하는 별도의 알림 생성
                        self.scheduleCheckNotification(for: snoozeAlarm, delay: snoozeDelayInSeconds + 30)
                        
                        // 백업으로 DispatchQueue도 사용
                        DispatchQueue.main.asyncAfter(deadline: .now() + snoozeDelayInSeconds + 30) { [weak self] in
                            guard let self = self else { return }
                            
                            // 중지 플래그 확인
                            if !self.isAlarmStopped(snoozeAlarm.id) {
                                self.startRepeatingAlarms(for: snoozeAlarm)
                            }
                        }
                    }
                }
            }
        }
    }
    
    /// 반복 알람 시작
    func startRepeatingAlarms(for alarm: Alarm) {
        let repeatInterval = alarm.repeatInterval
        let alarmId = alarm.id
        
        guard repeatInterval > 0 else { return }
        
        // 중지된 알람인지 확인
        if isAlarmStopped(alarmId) { return }
        
        // 스누즈 알람인 경우 다시 1분 후에 스누즈 알람 설정
        if isSnoozeAlarm(alarmId) {
            scheduleSnoozeAlarm(for: alarmId, minutes: 1)
            return
        }
        
        // 중앙화된 메서드를 사용하여 반복 알람용 콘텐츠 생성
        let content = createAlarmContent(type: .missed, for: alarm)
        
        // 트리거 생성 (설정된 분 간격)
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: TimeInterval(repeatInterval * 60),
            repeats: false
        )
        
        // 반복 알람 요청 생성
        let requestId = "\(alarm.id.uuidString)-repeat-\(UUID().uuidString)"
        let request = UNNotificationRequest(
            identifier: requestId,
            content: content,
            trigger: trigger
        )
        
        // 알림 등록
        UNUserNotificationCenter.current().add(request) { [weak self] error in
            guard let self = self else { return }
            
            if error == nil {
                // 이 반복 알람이 표시된 후, 사용자가 여전히 응답하지 않는 경우에 대비
                let nextCheckDelay = TimeInterval(repeatInterval * 60) + 5 // 5초 추가 지연
                
                DispatchQueue.main.asyncAfter(deadline: .now() + nextCheckDelay) { [weak self] in
                    guard let self = self else { return }
                    
                    // 중지 플래그 확인
                    if self.stoppedAlarmTimes[alarmId] == nil {
                        self.startRepeatingAlarms(for: alarm)  // 재귀적으로 계속 반복
                    }
                }
            }
        }
    }
    
    /// 반복 알람 중지
    func stopRepeatingAlarms(for alarmId: UUID) {
        safelyExecuteOnMainThread {
            let now = Date()
            self.stoppedAlarmTimes[alarmId] = now
        }
    }
    
    /// 중지 플래그 초기화
    func resetStopFlag(for alarmId: UUID) {
        safelyExecuteOnMainThread {
            self.stoppedAlarmTimes.removeValue(forKey: alarmId)
        }
    }
    
    /// 알람이 중지되었는지 확인
    func isAlarmStopped(_ alarmId: UUID) -> Bool {
        return stoppedAlarmTimes[alarmId] != nil
    }
    
    // MARK: - Notification Content Helpers
    
    /// 알람 알림 콘텐츠 생성을 위한 헬퍼 메서드
    private func createAlarmContent(type: AlarmNotificationType, for alarm: Alarm, batchId: String? = nil) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.sound = UNNotificationSound.default
        content.categoryIdentifier = "ALARM_CATEGORY"
        
        // 알림 유형에 따라 콘텐츠 설정
        switch type {
        case .main:
            content.title = "⏰ 알람 시간"
            content.body = "알람이 울렸습니다!"
            content.userInfo = [
                "alarm_id": alarm.id.uuidString,
                "sequence": 0,
                "timestamp": Date().timeIntervalSince1970,
                "batch_id": batchId ?? UUID().uuidString,
                "repeat_interval": alarm.repeatInterval
            ]
            
        case .followUp(let sequence):
            content.title = "\(alarm.title.isEmpty ? "알람" : alarm.title) (반복 \(sequence))"
            content.body = "놓친 알람이 있습니다!"
            content.userInfo = [
                "alarm_id": alarm.id.uuidString,
                "sequence": sequence,
                "timestamp": Date().timeIntervalSince1970,
                "batch_id": batchId ?? UUID().uuidString,
                "repeat_interval": alarm.repeatInterval
            ]
            
        case .missed:
            content.title = "⏰ 놓친 알람"
            content.body = "\(alarm.title) 알람을 확인해주세요!"
            content.userInfo = [
                "alarm_id": alarm.id.uuidString,
                "is_repeat": true,
                "timestamp": Date().timeIntervalSince1970,
                "repeat_interval": alarm.repeatInterval
            ]
            
        case .snooze:
            content.title = "\(alarm.title) (스누즈)"
            content.body = "스누즈된 알람이 울렸습니다."
            content.userInfo = [
                "alarm_id": alarm.id.uuidString,
                "is_snooze": true,
                "timestamp": Date().timeIntervalSince1970,
                "repeat_interval": alarm.repeatInterval
            ]
            
        case .check:
            content.title = "알람 체크" // 실제로는 표시되지 않음
            content.sound = nil
            content.categoryIdentifier = "ALARM_CHECK_CATEGORY"
            content.userInfo = [
                "alarm_id": alarm.id.uuidString,
                "is_check": true,
                "timestamp": Date().timeIntervalSince1970
            ]
        }
        
        return content
    }
    
    /// 알람 ID로 알람 정보 가져오기
    internal func getAlarmById(_ alarmId: UUID) -> Alarm? {
        // 실제 저장소에서 알람 정보 가져오기
        if let alarms = try? AlarmStorage.shared.loadAlarms(),
           let alarm = alarms.first(where: { $0.id == alarmId }) {
            return alarm
        }
        return nil
    }
    
    // MARK: - Private Methods
    
    // 새로운 알람 배치 생성
    private func createNewAlarmBatch(for alarm: Alarm, completion: @escaping (Bool) -> Void) {
        let alarmDate = getValidAlarmTime(for: alarm)
        
        // 먼저 현재 보류 중인 모든 알림 확인
        UNUserNotificationCenter.current().getPendingNotificationRequests { existingRequests in
            // 같은 알람 ID에 대한 알림이 있는지 확인
            let existingAlarmRequests = existingRequests.filter {
                $0.identifier.contains(alarm.id.uuidString)
            }
            
            if !existingAlarmRequests.isEmpty {
                UNUserNotificationCenter.current().removePendingNotificationRequests(
                    withIdentifiers: existingAlarmRequests.map { $0.identifier }
                )
            }
            
            // 새 알림 추가 진행
            self.scheduleActualNotifications(for: alarm, at: alarmDate, completion: completion)
        }
    }
    
    // 실제 알림 등록 로직
    private func scheduleActualNotifications(for alarm: Alarm, at alarmDate: Date, completion: @escaping (Bool) -> Void) {
        // 알림 생성 (첫 알람 포함 총 6개)
        let alarmCount = 6
        
        // 알람 상태 추적용 카운터
        var successCount = 0
        var failureCount = 0
        let group = DispatchGroup()
        
        // 고유한 배치 ID 생성 (모든 알림에 공통으로 사용)
        let batchId = UUID().uuidString
        
        // 알람 시간에 소리 트리거 설정 (첫 알람이 울릴 때)
        scheduleSoundTrigger(for: alarmDate)
        
        // 먼저 기존의 요청들을 확인
        UNUserNotificationCenter.current().getPendingNotificationRequests { existingRequests in
            for i in 0..<alarmCount {
                group.enter()
                
                // 알림 콘텐츠 생성 (중앙화된 메서드 사용)
                let notificationType = i == 0 ? AlarmNotificationType.main : AlarmNotificationType.followUp(i)
                let content = self.createAlarmContent(type: notificationType, for: alarm, batchId: batchId)
                
                // 알람 시간 계산
                var triggerDate = alarmDate
                
                if i > 0 {
                    // 기본 동작은 항상 2초 간격 (초기 알림들)
                    triggerDate = Calendar.current.date(byAdding: .second, value: i * 2, to: alarmDate) ?? alarmDate
                }
                
                // 트리거 생성
                let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: triggerDate)
                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
                
                // 고유 식별자 생성
                let requestId = i == 0
                ? "\(alarm.id.uuidString)-main-\(i)-\(batchId)"
                : "\(alarm.id.uuidString)-follow-\(i)-\(batchId)"
                
                // 정확히 같은 식별자의 알림이 있는지 확인
                let duplicateRequests = existingRequests.filter { $0.identifier == requestId }
                if !duplicateRequests.isEmpty {
                    group.leave()
                    continue
                }
                
                let request = UNNotificationRequest(identifier: requestId, content: content, trigger: trigger)
                
                // 알림 등록
                UNUserNotificationCenter.current().add(request) { error in
                    defer { group.leave() }
                    
                    if let error = error {
                        print("알림 등록 오류: \(error.localizedDescription)")
                        failureCount += 1
                    } else {
                        successCount += 1
                        
                        // 첫 번째 알람에 대해서만 반복 타이머 설정
                        if i == 0 && alarm.repeatInterval > 0 {
                            // 안전하게 메인 스레드에서 실행
                            DispatchQueue.main.async {
                                self.scheduleRepetitionTimer(for: alarm, initialDelay: 30) // 초기 알람 후 30초 대기
                            }
                        }
                    }
                }
            }
            
            // 모든 알림 등록 완료 후 결과 반환
            group.notify(queue: .main) {
                let success = failureCount == 0 && successCount > 0
                completion(success)
            }
        }
    }
    
    // 특정 시간 후에 알람 반복 체크를 위한 알림 예약
    private func scheduleCheckNotification(for alarm: Alarm, delay: TimeInterval) {
        // 체크용 알람 콘텐츠 생성
        let content = createAlarmContent(type: .check, for: alarm)
        
        // 지정된 딜레이 후 트리거
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
        
        // 요청 생성
        let requestId = "\(alarm.id.uuidString)-check-\(UUID().uuidString)"
        let request = UNNotificationRequest(identifier: requestId, content: content, trigger: trigger)
        
        // 알림 등록
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("알람 체크 알림 등록 오류: \(error.localizedDescription)")
            }
        }
    }
    
    // 특정 시간에 소리를 재생하기 위한 타이머 설정
    private func scheduleSoundTrigger(for date: Date) {
        // 현재 시간과 알람 시간의 차이 계산
        let timeInterval = date.timeIntervalSinceNow
        
        // 이미 지난 시간이거나 너무 가까운 시간은 즉시 처리
        if timeInterval <= 0 {
            playAlarmSound()
            return
        }
        
        // 백그라운드 작업 종료 (이전에 실행 중인 것이 있다면)
        endBackgroundTask()
        
        // 새 백그라운드 작업 시작
        backgroundTaskID = UIApplication.shared.beginBackgroundTask { [weak self] in
            // 시간이 만료되면 작업 종료
            self?.endBackgroundTask()
        }
        
        // 타이머 설정
        DispatchQueue.main.asyncAfter(deadline: .now() + timeInterval) { [weak self] in
            guard let self = self else { return }
            
            // 알람 소리 재생
            self.playAlarmSound()
            
            // 백그라운드 작업 종료
            self.endBackgroundTask()
        }
    }
    
    // 알람 소리 자동 중지 타이머 시작
    private func startAlarmSoundTimer() {
        // 이전 타이머가 있다면 중지
        alarmSoundTimer?.invalidate()
        
        // 새 타이머 시작
        alarmSoundTimer = Timer.scheduledTimer(withTimeInterval: defaultAlarmDuration, repeats: false) { [weak self] _ in
            self?.stopAlarmSound()
        }
    }
    
    // 시스템 사운드 반복 타이머 시작
    private func startSystemSoundRepeatTimer() {
        // 이미 타이머가 실행 중이면 중지
        stopSystemSoundRepeatTimer()
        
        isPlayingAlarmSound = true
        
        // 1초 간격으로 시스템 사운드 재생
        systemSoundTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            // 시스템 알람 사운드 재생
            let systemSoundID: SystemSoundID = 1005
            AudioServicesPlaySystemSound(systemSoundID)
        }
    }
    
    // 시스템 사운드 반복 타이머 중지
    private func stopSystemSoundRepeatTimer() {
        systemSoundTimer?.invalidate()
        systemSoundTimer = nil
    }
    
    // 알람 리소스 정리 (소리, 백그라운드 작업, 플래그 등)
    private func cleanupAlarmResources(alarmId: UUID) {
        // 알람 소리 중지
        stopAlarmSound()
        
        // 백그라운드 작업 종료
        endBackgroundTask()
        
        // 스누즈 알람 표시 제거
        snoozeAlarmIds.remove(alarmId)
        
        // 중지 플래그 설정
        safelyExecuteOnMainThread {
            stoppedAlarmTimes[alarmId] = Date()
        }
    }
    
    // 오늘 요일에 해당하는 반복 알람만 취소
    private func cancelRepeatingAlarmForToday(alarmId: UUID) {
        let today = Calendar.current.component(.weekday, from: Date())
        let todayIdentifier = "\(alarmId.uuidString)-\(today)"
        
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            // 관련된 알람 요청 찾기
            let relatedRequests = requests.filter { $0.identifier.contains(alarmId.uuidString) }
            
            let identifiersToRemove = relatedRequests
                .filter { request in
                    // 오늘 요일 기본 알람이거나 알람 ID를 포함하는 모든 요청
                    request.identifier == todayIdentifier || request.identifier.contains(alarmId.uuidString)
                }
                .map { $0.identifier }
            
            if !identifiersToRemove.isEmpty {
                UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiersToRemove)
            }
        }
    }
    
    // 일회성 알람 취소 (모든 관련 알림 제거)
    private func cancelNonRepeatingAlarm(alarmId: UUID) {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let identifiersToRemove = requests
                .filter { $0.identifier.contains(alarmId.uuidString) }
                .map { $0.identifier }
            
            if !identifiersToRemove.isEmpty {
                UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiersToRemove)
            }
        }
    }
    
    // 알람이 무시된 경우를 위한 반복 타이머 설정
    private func scheduleRepetitionTimer(for alarm: Alarm, initialDelay: TimeInterval = 30) {
        let repeatInterval = alarm.repeatInterval
        let alarmId = alarm.id
        
        guard repeatInterval > 0 else { return }
        
        // 호출 직후 즉시 중지 플래그 제거
        safelyExecuteOnMainThread {
            stoppedAlarmTimes.removeValue(forKey: alarmId)
        }
        
        // 첫 알람 이후에 반복 타이머를 시작하기 위한 딜레이
        DispatchQueue.main.asyncAfter(deadline: .now() + initialDelay) { [weak self] in
            guard let self = self, !self.isAlarmStopped(alarmId) else { return }
            
            // 명시적으로 취소되지 않았으므로 반복 알람 시작
            self.startRepeatingAlarms(for: alarm)
        }
    }
    
    // 스누즈 알람인지 확인
    private func isSnoozeAlarm(_ alarmId: UUID) -> Bool {
        return snoozeAlarmIds.contains(alarmId)
    }
    
    // 백그라운드 작업 종료
    private func endBackgroundTask() {
        if backgroundTaskID != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTaskID)
            backgroundTaskID = .invalid
        }
    }
    
    // 안전하게 메인 스레드에서 실행하는 헬퍼 메서드
    private func safelyExecuteOnMainThread(_ action: () -> Void) {
        if Thread.isMainThread {
            action()
        } else {
            DispatchQueue.main.sync(execute: action)
        }
    }
    
    // 유효한 알람 시간 가져오기 (항상 현재 이후의 시간)
    private func getValidAlarmTime(for alarm: Alarm) -> Date {
        var alarmDate = alarm.time
        
        // 일회성 알람의 경우
        if alarm.days.isEmpty {
            // 오늘 날짜에 알람 시간 설정
            alarmDate = combineDateAndTime(Date(), alarm.time)
            
            // 이미 지난 시간이면 최소 10초 후로 설정 (테스트 목적)
            if alarmDate < Date() {
                alarmDate = Date().addingTimeInterval(10)
            }
        }
        
        return alarmDate
    }
    
    // 날짜와 시간 결합하기
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
    
    // 시간 포맷팅
    private func formatTime(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - 알람 알림 핸들러 (AppDelegate 확장)
extension AppDelegate: UNUserNotificationCenterDelegate {
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // 알림의 내용 확인
        let userInfo = notification.request.content.userInfo
        
        // 알람 체크 알림인 경우 (스누즈 알람 자동 반복 체크)
        if userInfo["is_check"] as? Bool == true,
           let alarmIdString = userInfo["alarm_id"] as? String,
           let alarmId = UUID(uuidString: alarmIdString) {
            // 알람이 여전히 활성 상태인지 확인
            if !AlarmNotificationManager.shared.isAlarmStopped(alarmId) {
                if let alarm = AlarmNotificationManager.shared.getAlarmById(alarmId) {
                    AlarmNotificationManager.shared.startRepeatingAlarms(for: alarm)
                }
            }
            
            // 체크 알림은 표시하지 않음
            completionHandler([])
            return
        }
        
        // 일반 알람 노티피케이션인 경우
        if let alarmIdString = userInfo["alarm_id"] as? String {
            // 알람 소리 재생
            AlarmNotificationManager.shared.playAlarmSound()
        }
        
        // 앱 실행 중에도 알림 표시
        if #available(iOS 14.0, *) {
            completionHandler([.banner, .sound])
        } else {
            completionHandler([.alert, .sound])
        }
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        
        // 알람 ID 추출
        guard let alarmIdString = userInfo["alarm_id"] as? String,
              let alarmId = UUID(uuidString: alarmIdString) else {
            completionHandler()
            return
        }
        
        // 응답 액션에 따라 처리
        switch response.actionIdentifier {
        case UNNotificationDefaultActionIdentifier:
            // 기본 액션: 알람 화면 표시
            showAlarmScreen(for: alarmId)
            
            // 전달된 알림도 모두 제거 (중복 표시 방지)
            UNUserNotificationCenter.current().removeAllDeliveredNotifications()
            
        case UNNotificationDismissActionIdentifier:
            // 알림 무시: 알람 소리 중지
            AlarmNotificationManager.shared.stopAlarmSound()
            
        case "SNOOZE_ACTION":
            // 스누즈 액션
            // 알람 소리 중지
            AlarmNotificationManager.shared.stopAlarmSound()
            
            // 모든 전달된 알림 제거 (중복 표시 방지)
            UNUserNotificationCenter.current().removeAllDeliveredNotifications()
            
            // 알림만 취소
            AlarmNotificationManager.shared.cancelAlarmNotifications(alarmId: alarmId) {
                // 알람 정보를 가져오고, 이 정보가 있을 때 스누즈 알람을 설정
                if let originalAlarm = AlarmNotificationManager.shared.getAlarmById(alarmId) {
                    // 스누즈 알람 설정 (1분 후 알람, 원래 알람의 반복 간격 유지)
                    AlarmNotificationManager.shared.scheduleSnoozeAlarm(for: alarmId, minutes: 1)
                }
            }
            
        case "STOP_ACTION":
            // 알람 중지 액션
            // 알람 소리 중지
            AlarmNotificationManager.shared.stopAlarmSound()
            
            // 명시적인 중지 플래그 설정 및 알림 취소
            AlarmNotificationManager.shared.cancelAlarm(alarmId: alarmId)
            
            // 보류 중인 알림 요청 모두 조회하여 제거 - 추가 보호 조치
            UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
                // 이 알람 ID와 관련된 모든 알림 요청 찾기
                let allRelatedRequests = requests.filter {
                    $0.identifier.contains(alarmId.uuidString) ||
                    ($0.content.userInfo["alarm_id"] as? String) == alarmId.uuidString
                }
                
                if !allRelatedRequests.isEmpty {
                    let identifiersToRemove = allRelatedRequests.map { $0.identifier }
                    UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiersToRemove)
                }
                
                // 모든 전달된 알림도 제거
                UNUserNotificationCenter.current().removeAllDeliveredNotifications()
            }
            
        default:
            AlarmNotificationManager.shared.stopAlarmSound()
        }
        
        completionHandler()
    }
    
    private func showAlarmScreen(for alarmId: UUID) {
        // 알람 ID로 알람 정보 가져오기
        guard let alarm = AlarmNotificationManager.shared.getAlarmById(alarmId) else {
            return
        }
        
        // 알람 소리는 유지하면서 알림만 취소
        AlarmNotificationManager.shared.cancelAlarmNotifications(alarmId: alarmId) {
            // 알림 취소 완료 후 화면 표시
            DispatchQueue.main.async {
                let alarmRingVC = AlarmRingViewController(alarm: alarm)
                alarmRingVC.modalPresentationStyle = .fullScreen
                
                guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
                    return
                }
                
                self.alarmWindow = UIWindow(windowScene: scene)
                self.alarmWindow?.rootViewController = alarmRingVC
                self.alarmWindow?.makeKeyAndVisible()
            }
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
            options: [.destructive, .foreground]
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
