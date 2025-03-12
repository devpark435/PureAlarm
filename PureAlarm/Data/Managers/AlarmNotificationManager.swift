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
}

class AlarmNotificationManager {
    static let shared = AlarmNotificationManager()
    
    // 알람 관리를 위한 추가 속성
    private var processingAlarms = Set<String>()
    private let processingQueue = DispatchQueue(label: "com.purealarm.notification.queue")
    
    // 오디오 관련 속성 추가
    private var audioPlayer: AVAudioPlayer?
    private var isPlayingAlarmSound = false
    
    // 백그라운드 작업 식별자
    private var backgroundTaskID: UIBackgroundTaskIdentifier = .invalid
    
    // 시스템 사운드를 1초 간격으로 반복 재생하기 위한 타이머
    private var systemSoundTimer: Timer?
    
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
    
    /// 알람 소리 재생
    // 알람 소리 재생
    func playAlarmSound() {
        guard !isPlayingAlarmSound else {
            print("알람 소리가 이미 재생 중입니다.")
            return
        }
        
        // 알람 소리 파일 경로 가져오기
        guard let soundURL = Bundle.main.url(forResource: "alarm_sound", withExtension: "mp3") else {
            print("알람 소리 파일을 찾을 수 없습니다. 시스템 사운드를 사용합니다.")
            
            // 번들에 소리 파일이 없는 경우 시스템 사운드 사용
            let systemSoundID: SystemSoundID = 1005 // 시스템 알람 소리
            AudioServicesPlaySystemSound(systemSoundID)
            
            // 시스템 사운드는 한 번만 재생되므로 반복 타이머 설정
            startSystemSoundRepeatTimer()
            
            return
        }
        
        do {
            // 오디오 세션 설정
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            
            // 플레이어 생성 및 재생
            audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
            audioPlayer?.numberOfLoops = -1 // 무한 반복
            audioPlayer?.volume = 1.0
            audioPlayer?.play()
            isPlayingAlarmSound = true
            print("알람 소리 재생 시작")
        } catch {
            print("알람 소리 재생 오류: \(error.localizedDescription)")
            
            // 오류 발생 시 시스템 사운드 사용
            let systemSoundID: SystemSoundID = 1005 // 시스템 알람 소리
            AudioServicesPlaySystemSound(systemSoundID)
            
            // 시스템 사운드 반복 타이머 설정
            startSystemSoundRepeatTimer()
        }
    }

    // 시스템 사운드 반복 타이머 시작
    private func startSystemSoundRepeatTimer() {
        // 이미 타이머가 실행 중이면 중지
        stopSystemSoundRepeatTimer()
        
        isPlayingAlarmSound = true
        
        // 1초 간격으로 시스템 사운드 재생
        systemSoundTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
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

    // 알람 소리 중지 (수정)
    func stopAlarmSound() {
        guard isPlayingAlarmSound else {
            return
        }
        
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
        
        print("알람 소리 재생 중지")
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
        
        print("알람 소리 타이머 설정: \(timeInterval)초 후")
        
        // 타이머 설정
        DispatchQueue.main.asyncAfter(deadline: .now() + timeInterval) { [weak self] in
            guard let self = self else { return }
            
            // 백그라운드 작업 시작
            self.beginBackgroundTask()
            
            // 알람 소리 재생
            self.playAlarmSound()
        }
    }

    // 백그라운드 작업 시작
    private func beginBackgroundTask() {
        // 이미 실행 중인 백그라운드 작업이 있다면 종료
        if backgroundTaskID != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTaskID)
            backgroundTaskID = .invalid
        }
        
        // 새 백그라운드 작업 시작
        backgroundTaskID = UIApplication.shared.beginBackgroundTask { [weak self] in
            guard let self = self else { return }
            // 시간이 만료되면 작업 종료
            UIApplication.shared.endBackgroundTask(self.backgroundTaskID)
            self.backgroundTaskID = .invalid
        }
    }

    // 백그라운드 작업 종료
    private func endBackgroundTask() {
        if backgroundTaskID != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTaskID)
            backgroundTaskID = .invalid
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
    
    /// 알람 예약 - 중복 방지 및 실패 이유 반환 로직 추가
    func scheduleAlarm(alarm: Alarm, completion: @escaping (Bool, ScheduleFailureReason?) -> Void) {
        // 알람이 활성화되어 있지 않으면 예약하지 않음
        guard alarm.isActive else {
            print("비활성 알람은 예약되지 않습니다: \(alarm.id)")
            completion(false, .inactiveAlarm)
            return
        }
        
        // 알람 ID 문자열
        let alarmIdString = alarm.id.uuidString
        
        // 중복 호출 방지를 위한 처리 - 처리 중인 알람이면 무시
        var shouldProceed = false
        
        processingQueue.sync {
            if processingAlarms.contains(alarmIdString) {
                print("⚠️ 경고: 알람 \(alarmIdString)는 이미 처리 중입니다. 중복 예약을 방지합니다. (시간: \(Date().timeIntervalSince1970))")
                // shouldProceed 플래그를 false로 유지
            } else {
                // 처리 중 표시
                processingAlarms.insert(alarmIdString)
                shouldProceed = true
            }
        }
        
        // 이미 처리 중인 알람이면 여기서 중단하고 중복 처리 이유 반환
        if !shouldProceed {
            DispatchQueue.main.async {
                // 중복 처리는 성공으로 간주하여 UI 오류 메시지 방지
                completion(true, .duplicateProcessing)
            }
            return
        }
        
        print("== 알람 예약 시작: \(alarm.id) (타임스탬프: \(Date().timeIntervalSince1970))")
        
        // 알람이 새로 설정될 때는 중지 플래그 제거 (반복 허용)
        resetStopFlag(for: alarm.id)
        
        // 기존 알람 관련 알림들 동기적으로 취소
        cancelAlarmNotifications(alarmId: alarm.id) {
            // 취소 완료 후 새 알람 생성
            self.createNewAlarmBatch(for: alarm) { success in
                // 완료 후 처리 중 표시 제거
                self.processingQueue.sync {
                    self.processingAlarms.remove(alarmIdString)
                }
                
                // 성공 또는 실패에 따라 결과 전달
                if !success {
                    completion(false, ScheduleFailureReason.notificationError)
                } else {
                    completion(true, nil)
                }
            }
        }
    }
    
    // 알람 알림만 취소 (중지 플래그 설정 없음) - 알람 재설정시 사용
    func cancelAlarmNotifications(alarmId: UUID, completion: @escaping () -> Void) {
        print("알람 알림만 취소 시작 (플래그 설정 없음): \(alarmId)")
        
        // 전달된(delivered) 알림도 함께 취소
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [alarmId.uuidString])
        
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
    
    /// 알람 취소 - 중지 플래그 설정 및 알림 제거
    func cancelAlarm(alarmId: UUID) {
        print("알람 취소 요청: \(alarmId)")
        
        // 알람 ID를 로그로 출력
        print("알람 취소 - 알람 ID: \(alarmId)")
        
        // 알람 소리 중지
        stopAlarmSound()
        
        // 백그라운드 작업 종료
        endBackgroundTask()
        
        // 명시적인 사용자 취소 동작 - 여기서만 중지 플래그 설정 (즉시 동기적으로)
        safelyExecuteOnMainThread {
            let now = Date()
            stoppedAlarmTimes[alarmId] = now
            print("알람 취소 - 중지 플래그 설정됨 (\(now))")
        }
        
        // 전달된 알림 제거
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [alarmId.uuidString])
        
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let identifiersToRemove = requests
                .filter { $0.identifier.contains(alarmId.uuidString) }
                .map { $0.identifier }
            
            if !identifiersToRemove.isEmpty {
                UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiersToRemove)
                print("알람 취소 - \(identifiersToRemove.count)개 알림 제거됨")
            } else {
                print("알람 취소 - 제거할 알림 없음")
            }
        }
    }
    
    // 안전하게 메인 스레드에서 실행하는 헬퍼 메서드
    private func safelyExecuteOnMainThread(_ action: () -> Void) {
        if Thread.isMainThread {
            // 이미 메인 스레드라면 직접 실행
            action()
        } else {
            // 메인 스레드가 아니라면 sync 호출
            DispatchQueue.main.sync(execute: action)
        }
    }
    
    // 반복 알람 중지를 위한 플래그 관리 - 시간 기준 설정으로 변경
    private var stoppedAlarmTimes = [UUID: Date]()
    
    // 외부에서 접근 가능하도록 public으로 변경
    func stopRepeatingAlarms(for alarmId: UUID) {
        safelyExecuteOnMainThread {
            let now = Date()
            self.stoppedAlarmTimes[alarmId] = now
            print("알람 ID \(alarmId)에 대한 반복 중지 플래그 설정됨 (\(now))")
        }
    }
    
    func resetStopFlag(for alarmId: UUID) {
        safelyExecuteOnMainThread {
            if let oldTime = self.stoppedAlarmTimes[alarmId] {
                self.stoppedAlarmTimes.removeValue(forKey: alarmId)
                print("알람 ID \(alarmId)에 대한 반복 중지 플래그 초기화됨 (이전 설정 시간: \(oldTime))")
            }
        }
    }
    
    private func isAlarmStopped(_ alarmId: UUID) -> Bool {
        // 단순화된 로직: 중지 플래그가 있으면 중지된 것으로 간주
        if let stopTime = stoppedAlarmTimes[alarmId] {
            print("알람 \(alarmId)는 중지됨 (시간: \(stopTime))")
            return true
        }
        return false
    }
    
    /// 모든 알람 취소
    func cancelAllAlarms() {
        print("모든 알람 취소 요청")
        
        // 알람 소리 중지
        stopAlarmSound()
        
        // 백그라운드 작업 종료
        endBackgroundTask()
        
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }
    
    /// 스누즈 알람 설정 - 반복 간격은 알람 모델의 repeatInterval 사용
    func scheduleSnoozeAlarm(for alarmId: UUID, minutes: Int = 5) {
        // 기존 알람 정보 가져오기
        guard let originalAlarm = getAlarmById(alarmId) else {
            print("스누즈: 알람 정보를 찾을 수 없음, 스누즈 설정 불가: \(alarmId)")
            return
        }
        
        // 반복 간격 로깅
        if originalAlarm.repeatInterval > 0 {
            print("스누즈: 알람 요청 - \(alarmId), \(minutes)분 후, 반복 간격: \(originalAlarm.repeatInterval)분")
        } else {
            print("스누즈: 알람 요청 - \(alarmId), \(minutes)분 후, 반복 없음")
        }
        
        // 기존 알람 관련 알림 모두 취소 (단, 중지 플래그는 설정하지 않음)
        cancelAlarmNotifications(alarmId: alarmId) {
            // 스누즈 시간 계산 (현재 시간 + minutes분)
            let snoozeDate = Date().addingTimeInterval(TimeInterval(minutes * 60))
            
            // 스누즈된 알람 객체 생성
            var snoozeAlarm = originalAlarm
            snoozeAlarm.time = snoozeDate
            snoozeAlarm.title = "\(originalAlarm.title) (스누즈)"
            
            // 중지 플래그 초기화 (새 알람이므로 이전 중지 상태를 무시)
            self.resetStopFlag(for: snoozeAlarm.id)
            
            // 스누즈 알람 예약 (원래 알람의 반복 간격 유지)
            self.scheduleAlarm(alarm: snoozeAlarm) { success, reason in
                if success {
                    print("스누즈: 알람 설정 완료 - \(minutes)분 후 (시간: \(self.formatTime(date: snoozeDate)))")
                    
                    // 스누즈 알람도 반복 타이머 설정
                    if snoozeAlarm.repeatInterval > 0 {
                        print("스누즈: 반복 타이머 설정 - \(snoozeAlarm.repeatInterval)분 간격")
                    }
                } else {
                    print("스누즈: 알람 설정 실패 - \(reason?.description ?? "알 수 없는 이유")")
                }
            }
        }
    }
    
    // 알람이 무시된 경우를 위한 반복 타이머 설정
    private func scheduleRepetitionTimer(for alarm: Alarm, initialDelay: TimeInterval = 30) {
        let repeatInterval = alarm.repeatInterval
        let alarmId = alarm.id
        
        guard repeatInterval > 0 else {
            print("반복 간격이 설정되지 않음, 반복 타이머 취소")
            return
        }
        
        print("알람 반복 타이머 설정: \(alarmId), \(initialDelay)초 후 체크, 반복 간격: \(repeatInterval)분")
        
        // 호출 직후 즉시 중지 플래그 제거
        safelyExecuteOnMainThread {
            stoppedAlarmTimes.removeValue(forKey: alarmId)
            print("알람 \(alarmId) 반복 타이머 설정 - 이전 중지 플래그 모두 초기화")
        }
        
        // 첫 알람 이후에 반복 타이머를 시작하기 위한 딜레이
        DispatchQueue.main.asyncAfter(deadline: .now() + initialDelay) { [weak self] in
            guard let self = self else {
                print("타이머 실행 시 self가 nil, 반복 취소")
                return
            }
            
            // 중지 플래그 재확인
            if self.isAlarmStopped(alarmId) {
                print("알람 \(alarmId)는 타이머 대기 중 다시 중지됨, 반복 취소")
                return
            }
            
            // 명시적으로 취소되지 않았으므로 반복 알람 시작
            print("알람 \(alarmId)에 대한 반응 없음, \(repeatInterval)분 간격으로 반복 알람 시작")
            self.startRepeatingAlarms(for: alarm)
        }
    }
    
    // 반복 알람 시작
    // 반복 알람 시작
    private func startRepeatingAlarms(for alarm: Alarm) {
        let repeatInterval = alarm.repeatInterval
        let alarmId = alarm.id
        
        guard repeatInterval > 0 else {
            print("반복 간격이 0이어서 반복 알람을 시작할 수 없음")
            return
        }
        
        // 중지된 알람인지 확인
        if isAlarmStopped(alarmId) {
            print("알람 \(alarmId)는 이미 중지됨, 반복 알람 예약 취소")
            return
        }
        
        // 첫 번째 반복 알람을 설정된 간격(분) 후에 예약
        let repeatDate = Date().addingTimeInterval(TimeInterval(repeatInterval * 60))
        print("다음 반복 알람 예약: \(formatTime(date: repeatDate)) (\(repeatInterval)분 후)")
        
        // 고유한 배치 ID 생성 (모든 알림에 공통으로 사용)
        let batchId = UUID().uuidString
        
        // 알람 상태 추적용 카운터
        var successCount = 0
        var failureCount = 0
        let group = DispatchGroup()
        
        // 여러 개의 알람 생성 (첫 알람 포함 총 6개)
        let alarmCount = 6
        
        for i in 0..<alarmCount {
            group.enter()
            
            // 알림 내용 설정
            let content = UNMutableNotificationContent()
            
            if i == 0 {
                // 첫 번째 알람
                content.title = "⏰ 놓친 알람"
                content.body = "\(alarm.title) 알람을 확인해주세요!"
            } else {
                // 후속 알람
                content.title = "⏰ 놓친 알람 (반복 \(i))"
                content.body = "\(alarm.title) 알람을 확인해주세요!"
            }
            
            content.sound = UNNotificationSound.default
            content.categoryIdentifier = "ALARM_CATEGORY"
            content.userInfo = [
                "alarm_id": alarm.id.uuidString,
                "is_repeat": true,
                "sequence": i,
                "timestamp": Date().timeIntervalSince1970,
                "batch_id": batchId,
                "repeat_interval": repeatInterval
            ]
            
            // 알람 시간 계산
            var triggerTime: TimeInterval
            
            if i == 0 {
                // 첫 번째 알람은 repeatInterval 분 후
                triggerTime = TimeInterval(repeatInterval * 60)
            } else {
                // 후속 알람은 첫 알람 이후 2초 간격으로
                triggerTime = TimeInterval(repeatInterval * 60) + TimeInterval(i * 2)
            }
            
            // 트리거 생성
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: triggerTime, repeats: false)
            
            // 고유 식별자 생성
            let requestId = i == 0
            ? "\(alarm.id.uuidString)-repeat-main-\(batchId)"
            : "\(alarm.id.uuidString)-repeat-follow-\(i)-\(batchId)"
            
            // 알림 요청 생성
            let request = UNNotificationRequest(identifier: requestId, content: content, trigger: trigger)
            
            // 알림 등록
            UNUserNotificationCenter.current().add(request) { error in
                defer { group.leave() }
                
                if let error = error {
                    print("반복 알람 \(i) 등록 오류: \(error.localizedDescription)")
                    failureCount += 1
                } else {
                    let triggerDate = Date().addingTimeInterval(triggerTime)
                    print("반복 알람 \(i) 등록 성공: \(self.formatTime(date: triggerDate)) (ID: \(requestId))")
                    successCount += 1
                }
            }
        }
        
        // 모든 알림 등록 완료 후
        group.notify(queue: .main) {
            print("반복 알람 배치 등록 완료 - 성공: \(successCount), 실패: \(failureCount)")
            
            // 다음 체크를 위한 딜레이 (현재 반복 간격 + 약간의 추가 시간)
            let nextCheckDelay = TimeInterval(repeatInterval * 60) + 10
            
            DispatchQueue.main.asyncAfter(deadline: .now() + nextCheckDelay) { [weak self] in
                guard let self = self else { return }
                
                // 중지 플래그 확인
                if self.stoppedAlarmTimes[alarmId] != nil {
                    print("알람 \(alarmId) 반복 체크: 이미 중지됨, 추가 반복 취소")
                    return
                }
                
                print("알람 \(alarmId) 반복 체크: 아직 활성, 다음 반복 알람 예약")
                self.startRepeatingAlarms(for: alarm)  // 재귀적으로 계속 반복
            }
        }
    }
    
    // 알람 상태 확인 (아직 활성 상태인지)
    private func checkAlarmStatus(alarmId: UUID, completion: @escaping (Bool) -> Void) {
        print("알람 상태 확인 중: \(alarmId)")
        
        // 중지 플래그가 설정되었는지 확인 (명시적 취소 여부)
        if isAlarmStopped(alarmId) {
            print("알람 \(alarmId)는 명시적으로 중지됨, 반복 중단")
            completion(false)
            return
        }
        
        // 명시적으로 중지되지 않은 경우는 항상 활성으로 간주 (반복 계속)
        print("알람 \(alarmId)는 중지되지 않음, 반복 계속")
        completion(true)
    }
    
    // 알람 ID로 알람 정보 가져오기
    internal func getAlarmById(_ alarmId: UUID) -> Alarm? {
        // 실제 저장소에서 알람 정보 가져오기
        if let alarms = try? AlarmStorage.shared.loadAlarms(),
           let alarm = alarms.first(where: { $0.id == alarmId }) {
            return alarm
        }
        
        // 저장소에서 찾지 못한 경우 nil 반환
        print("저장소에서 알람을 찾지 못함: \(alarmId)")
        return nil
    }
    
    // MARK: - Private Methods
    
    // 새로운 알람 배치 생성 메서드 - 중복 방지 로직 추가
    private func createNewAlarmBatch(for alarm: Alarm, completion: @escaping (Bool) -> Void) {
        let alarmDate = getValidAlarmTime(for: alarm)
        print("알람 시간 계산됨: \(formatTime(date: alarmDate))")
        
        // 먼저 현재 보류 중인 모든 알림 확인
        UNUserNotificationCenter.current().getPendingNotificationRequests { existingRequests in
            // 같은 알람 ID에 대한 알림이 있는지 확인
            let existingAlarmRequests = existingRequests.filter {
                $0.identifier.contains(alarm.id.uuidString)
            }
            
            if !existingAlarmRequests.isEmpty {
                print("⚠️ 경고: 동일한 알람 ID에 대한 알림이 \(existingAlarmRequests.count)개 이미 존재합니다. 모두 취소합니다.")
                UNUserNotificationCenter.current().removePendingNotificationRequests(
                    withIdentifiers: existingAlarmRequests.map { $0.identifier }
                )
            }
            
            // 이제 새 알림 추가 진행
            self.scheduleActualNotifications(for: alarm, at: alarmDate, completion: completion)
        }
    }
    
    // 실제 알림 등록 로직 분리
    private func scheduleActualNotifications(for alarm: Alarm, at alarmDate: Date, completion: @escaping (Bool) -> Void) {
        // 알림 생성 (첫 알람 포함 총 6개)
        let alarmCount = 6
        
        // 반복 간격 (분) 로그 출력
        if alarm.repeatInterval > 0 {
            print("알람 반복 간격 설정됨: \(alarm.repeatInterval)분")
        }
        
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
                    "timestamp": Date().timeIntervalSince1970,
                    "batch_id": batchId, // 배치 ID 추가
                    "repeat_interval": alarm.repeatInterval // 반복 간격 추가
                ]
                
                // 알람 시간 계산
                var triggerDate = alarmDate
                
                if i > 0 {
                    // 기본 동작은 항상 2초 간격 (초기 알림들)
                    triggerDate = Calendar.current.date(byAdding: .second, value: i * 2, to: alarmDate) ?? alarmDate
                }
                
                // 트리거 생성
                let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: triggerDate)
                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
                
                // 고유 식별자 생성 (시퀀스와 배치 ID 모두 포함)
                let requestId = i == 0
                ? "\(alarm.id.uuidString)-main-\(i)-\(batchId)"
                : "\(alarm.id.uuidString)-follow-\(i)-\(batchId)"
                
                // 정확히 같은 식별자의 알림이 있는지 확인
                let duplicateRequests = existingRequests.filter { $0.identifier == requestId }
                if !duplicateRequests.isEmpty {
                    print("⚠️ 중복 경고: 식별자 \(requestId)와 동일한 알림이 이미 존재합니다. 스킵합니다.")
                    group.leave()
                    continue
                }
                
                let request = UNNotificationRequest(identifier: requestId, content: content, trigger: trigger)
                
                // 알림 등록
                UNUserNotificationCenter.current().add(request) { error in
                    defer { group.leave() }
                    
                    if let error = error {
                        print("알림 \(i) 등록 오류: \(error.localizedDescription)")
                        failureCount += 1
                    } else {
                        print("알림 \(i) 등록 성공: \(self.formatTime(date: triggerDate)) (ID: \(requestId))")
                        successCount += 1
                        
                        // 첫 번째 알람에 대해서만 반복 타이머 설정
                        if i == 0 && alarm.repeatInterval > 0 {
                            print("첫 번째 알람에 대한 반복 타이머 설정 - \(alarm.repeatInterval)분 간격")
                            
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
                print("알람 등록 완료 - 성공: \(successCount), 실패: \(failureCount)")
                completion(success)
            }
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

// MARK: - ScheduleFailureReason에 대한 설명 추가
extension ScheduleFailureReason {
    var description: String {
        switch self {
        case .inactiveAlarm:
            return "비활성 알람"
        case .duplicateProcessing:
            return "이미 처리 중인 알람"
        case .notificationError:
            return "알림 등록 오류"
        }
    }
}

// MARK: - 알람 알림 핸들러
extension AppDelegate: UNUserNotificationCenterDelegate {
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        // 알림의 내용 확인
        let userInfo = notification.request.content.userInfo
        
        // 알람 ID가 있는지 확인 (알람 노티피케이션인 경우)
        if let alarmIdString = userInfo["alarm_id"] as? String {
            print("알람 노티피케이션 표시 - 알람 소리 재생 시작")
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
            AlarmNotificationManager.shared.stopAlarmSound()
            showAlarmScreen(for: alarmId)
            
            // 전달된 알림도 모두 제거 (중복 표시 방지)
            UNUserNotificationCenter.current().removeAllDeliveredNotifications()
            
        case UNNotificationDismissActionIdentifier:
            // 알림 무시: 알람 소리 중지
            print("알림 무시됨")
            AlarmNotificationManager.shared.stopAlarmSound()
            break
            
        case "SNOOZE_ACTION":
            // 스누즈 액션
            print("스누즈 액션 실행")
            
            // 알람 소리 중지
            AlarmNotificationManager.shared.stopAlarmSound()
                    
            
            // 모든 전달된 알림 제거 (중복 표시 방지)
            UNUserNotificationCenter.current().removeAllDeliveredNotifications()
            
            // 현재 알람 중지 (더 이상 반복 없음)
            AlarmNotificationManager.shared.cancelAlarm(alarmId: alarmId)
            
            // 알람 정보를 가져오고, 이 정보가 있을 때 스누즈 알람을 설정
            if let originalAlarm = AlarmNotificationManager.shared.getAlarmById(alarmId) {
                print("스누즈 알람 설정 - 원본 알람: \(originalAlarm.title), 반복 간격: \(originalAlarm.repeatInterval)분")
                
                // 스누즈 알람 설정 (5분 후 알람, 원래 알람의 반복 간격 유지)
                AlarmNotificationManager.shared.scheduleSnoozeAlarm(for: alarmId)
            } else {
                print("알람 정보를 찾을 수 없음, 스누즈 설정 불가")
            }
            
        case "STOP_ACTION":
            // 알람 중지 액션
            print("알람 중지 액션 - 모든 관련 알림 취소")
            
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
                    print("알람 중지 - 추가로 \(identifiersToRemove.count)개의 관련 알림 제거됨")
                }
                
                // 모든 전달된 알림도 제거
                UNUserNotificationCenter.current().removeAllDeliveredNotifications()
                print("모든 전달된 알림 제거 완료")
            }
            break
            
        default:
            print("알 수 없는 액션: \(response.actionIdentifier)")
            AlarmNotificationManager.shared.stopAlarmSound()
            break
        }
        
        completionHandler()
    }
    
    private func showAlarmScreen(for alarmId: UUID) {
        print("showAlarmScreen 메서드 호출됨: \(alarmId)")
        
        // 알람 ID로 알람 정보 가져오기
        guard let alarm = AlarmNotificationManager.shared.getAlarmById(alarmId) else {
            print("알람 정보 가져오기 실패: \(alarmId), 화면 표시 불가")
            return
        }
        
        print("알람 정보 가져오기 성공: \(alarm.title)")
        
        // 명시적으로 알람 중지 플래그 설정 및 관련 알림 모두 취소
        AlarmNotificationManager.shared.cancelAlarm(alarmId: alarmId)
        
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
