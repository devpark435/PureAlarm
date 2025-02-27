//
//  AlarmRingViewController.swift
//  PureAlarm
//
//  Created by 박현렬 on 2/27/25.
//

import UIKit
import SnapKit
import Then
import AVFoundation

class AlarmRingViewController: UIViewController {
    
    // MARK: - Properties
    private var alarm: Alarm
    private var player: AVAudioPlayer?
    private var vibrationTimer: Timer?
    private var isSnoozeEnabled: Bool
    
    // MARK: - UI Components
    private let gradientBackgroundView = GradientView(
        colors: [
            UIColor(red: 0.05, green: 0.05, blue: 0.1, alpha: 1.0),
            UIColor(red: 0.1, green: 0.1, blue: 0.2, alpha: 1.0)
        ]
    )
    
    private let timeLabel = UILabel().then {
        $0.textColor = .white
        $0.font = .systemFont(ofSize: 80, weight: .light)
        $0.textAlignment = .center
    }
    
    private let dateLabel = UILabel().then {
        $0.textColor = UIColor(white: 0.8, alpha: 1.0)
        $0.font = .systemFont(ofSize: 20)
        $0.textAlignment = .center
    }
    
    private let titleLabel = UILabel().then {
        $0.textColor = .white
        $0.font = .systemFont(ofSize: 24, weight: .medium)
        $0.textAlignment = .center
    }
    
    private let sliderContainer = UIView().then {
        $0.backgroundColor = UIColor(white: 0.15, alpha: 1.0)
        $0.layer.cornerRadius = 30
    }
    
    private let sliderTrack = UIView().then {
        $0.backgroundColor = UIColor(white: 0.3, alpha: 1.0)
        $0.layer.cornerRadius = 24
    }
    
    private let sliderThumb = UIView().then {
        $0.backgroundColor = .white
        $0.layer.cornerRadius = 24
        $0.layer.shadowColor = UIColor.black.cgColor
        $0.layer.shadowOffset = CGSize(width: 0, height: 2)
        $0.layer.shadowRadius = 4
        $0.layer.shadowOpacity = 0.3
    }
    
    private let alarmIconImageView = UIImageView().then {
        $0.image = UIImage(systemName: "alarm.fill")
        $0.contentMode = .scaleAspectFit
        $0.tintColor = .white
    }
    
    private let slideToStopLabel = UILabel().then {
        $0.text = "밀어서 알람 끄기"
        $0.textColor = .white
        $0.font = .systemFont(ofSize: 16)
        $0.textAlignment = .center
    }
    
    private let snoozeButton = UIButton().then {
        $0.setTitle("5분 후에 다시 알림", for: .normal)
        $0.setTitleColor(.white, for: .normal)
        $0.backgroundColor = UIColor(white: 0.2, alpha: 1.0)
        $0.layer.cornerRadius = 20
    }
    
    // MARK: - Initialization
    init(alarm: Alarm) {
        self.alarm = alarm
        self.isSnoozeEnabled = alarm.snooze
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        setupCurrentTime()
        setupAlarmInfo()
        setupGestures()
        startAlarmSound()
        
        if alarm.vibration {
            startVibration()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopAlarm()
    }
    
    // MARK: - UI Configuration
    private func configureUI() {
        view.addSubview(gradientBackgroundView)
        gradientBackgroundView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        view.addSubviews(timeLabel, dateLabel, titleLabel, sliderContainer)
        
        timeLabel.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(60)
            $0.centerX.equalToSuperview()
        }
        
        dateLabel.snp.makeConstraints {
            $0.top.equalTo(timeLabel.snp.bottom).offset(8)
            $0.centerX.equalToSuperview()
        }
        
        titleLabel.snp.makeConstraints {
            $0.top.equalTo(dateLabel.snp.bottom).offset(40)
            $0.centerX.equalToSuperview()
            $0.leading.trailing.equalToSuperview().inset(20)
        }
        
        sliderContainer.snp.makeConstraints {
            $0.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-80)
            $0.centerX.equalToSuperview()
            $0.width.equalTo(300)
            $0.height.equalTo(60)
        }
        
        sliderContainer.addSubviews(sliderTrack, slideToStopLabel)
        
        sliderTrack.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(6)
            $0.trailing.equalToSuperview().offset(-6)
            $0.centerY.equalToSuperview()
            $0.height.equalTo(48)
        }
        
        slideToStopLabel.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
        
        sliderTrack.addSubview(sliderThumb)
        sliderThumb.snp.makeConstraints {
            $0.leading.equalTo(sliderTrack.snp.leading)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(48)
        }
        
        sliderThumb.addSubview(alarmIconImageView)
        alarmIconImageView.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.size.equalTo(24)
        }
        
        // 스누즈 버튼 (스누즈가 활성화된 경우에만)
        if isSnoozeEnabled {
            view.addSubview(snoozeButton)
            snoozeButton.snp.makeConstraints {
                $0.bottom.equalTo(sliderContainer.snp.top).offset(-30)
                $0.centerX.equalToSuperview()
                $0.width.equalTo(200)
                $0.height.equalTo(44)
            }
            
            snoozeButton.addTarget(self, action: #selector(snoozeButtonTapped), for: .touchUpInside)
        }
    }
    
    private func setupCurrentTime() {
        let now = Date()
        
        // 시간 포맷
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        timeLabel.text = timeFormatter.string(from: now)
        
        // 날짜 포맷
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "M월 d일 EEEE"
        dateFormatter.locale = Locale(identifier: "ko_KR")
        dateLabel.text = dateFormatter.string(from: now)
        
        // 1초마다 시간 업데이트
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            let currentTime = Date()
            self?.timeLabel.text = timeFormatter.string(from: currentTime)
        }
    }
    
    private func setupAlarmInfo() {
        titleLabel.text = alarm.title.isEmpty ? "알람" : alarm.title
    }
    
    private func setupGestures() {
        // 슬라이더용 팬 제스처
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handleSliderPan(_:)))
        sliderThumb.addGestureRecognizer(panGesture)
        sliderThumb.isUserInteractionEnabled = true
    }
    
    // MARK: - Alarm Functions
    private func startAlarmSound() {
        // 알람 소리 재생 (예시: 기본 알람 소리)
        guard let soundURL = Bundle.main.url(forResource: "alarm_sound", withExtension: "mp3") else {
            // 번들에 소리 파일이 없는 경우 시스템 사운드 사용
            let systemSoundID: SystemSoundID = 1005 // 시스템 알람 소리
            AudioServicesPlaySystemSound(systemSoundID)
            return
        }
        
        do {
            // 오디오 세션 설정
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            
            // 플레이어 생성 및 재생
            player = try AVAudioPlayer(contentsOf: soundURL)
            player?.numberOfLoops = -1 // 무한 반복
            player?.volume = 1.0
            player?.play()
        } catch {
            print("알람 소리 재생 오류: \(error.localizedDescription)")
        }
    }
    
    private func startVibration() {
        // 진동 타이머 시작 (1초마다 진동)
        vibrationTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        }
    }
    
    private func stopAlarm() {
        // 사운드 정지
        player?.stop()
        player = nil
        
        // 진동 정지
        vibrationTimer?.invalidate()
        vibrationTimer = nil
        
        // 오디오 세션 비활성화
        do {
            try AVAudioSession.sharedInstance().setActive(false)
        } catch {
            print("오디오 세션 비활성화 오류: \(error.localizedDescription)")
        }
    }
    
    // MARK: - User Actions
    @objc private func handleSliderPan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: sliderTrack)
        let maxSlideDistance = sliderTrack.bounds.width - sliderThumb.bounds.width
        
        switch gesture.state {
        case .changed:
            // 슬라이더 이동 (왼쪽에서 오른쪽으로만)
            var newX = sliderThumb.frame.origin.x + translation.x
            newX = max(0, min(newX, maxSlideDistance))
            
            sliderThumb.frame.origin.x = newX
            gesture.setTranslation(.zero, in: sliderTrack)
            
            // 슬라이더 진행도에 따라 레이블 투명도 조정
            let progress = newX / maxSlideDistance
            slideToStopLabel.alpha = 1.0 - progress
            
        case .ended:
            // 슬라이더가 끝까지 도달했는지 확인
            if sliderThumb.frame.origin.x >= maxSlideDistance * 0.8 {
                // 슬라이더를 끝까지 애니메이션으로 이동
                UIView.animate(withDuration: 0.2, animations: {
                    self.sliderThumb.frame.origin.x = maxSlideDistance
                    self.slideToStopLabel.alpha = 0
                }) { _ in
                    self.dismissAlarm()
                }
            } else {
                // 슬라이더를 시작 위치로 되돌림
                UIView.animate(withDuration: 0.2) {
                    self.sliderThumb.frame.origin.x = 0
                    self.slideToStopLabel.alpha = 1.0
                }
            }
            
        default:
            break
        }
    }
    
    @objc private func snoozeButtonTapped() {
        // 스누즈 로직 구현
        // 5분 후에 다시 알람이 울리도록 설정
        scheduleSnooze()
        
        // 알람 종료 및 화면 닫기
        stopAlarm()
        dismiss(animated: true)
    }
    
    // MARK: - Helper Methods
    private func dismissAlarm() {
        // 알람 종료
        stopAlarm()
        
        // 화면 닫기
        UIApplication.shared.perform(#selector(NSXPCConnection.suspend))
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            exit(0)
        }
    }
    
    private func scheduleSnooze() {
        // 현재 시간에서 5분 후 시간 계산 (현지 시간대 고려)
        let calendar = Date.currentCalendar
        let now = Date()
        
        // 현재 시간에서 5분을 더한 시간
        guard let snoozeTime = calendar.date(byAdding: .minute, value: 5, to: now) else {
            print("스누즈 시간 계산 오류")
            return
        }
        
        // 시간 정보 추출 (디버깅용)
        let hour = calendar.component(.hour, from: snoozeTime)
        let minute = calendar.component(.minute, from: snoozeTime)
        print("스누즈 설정 (현지 시간): \(hour)시 \(minute)분")
        
        // AlarmNotificationManager를 통해 스누즈 알람 설정
        AlarmNotificationManager.shared.scheduleSnoozeAlarm(for: alarm.id, minutes: 5)
        
        DispatchQueue.main.async { [weak self] in
            self?.presentingViewController?.dismiss(animated: true)
        }
        
    }
    
}
