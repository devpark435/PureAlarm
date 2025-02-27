//
//  Date+Extensions.swift
//  PureAlarm
//
//  Created by 박현렬 on 2/26/25.
//

import Foundation

extension Date {
    func getFormattedTime() -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }
    // 현재 시간대의 캘린더 반환
    static var currentCalendar: Calendar {
        var calendar = Calendar.current
        calendar.timeZone = TimeZone.current
        return calendar
    }
    
    // 사용자 시간대에 맞는 날짜 생성 (시간, 분만 지정)
    static func createLocalTime(hour: Int, minute: Int) -> Date {
        let calendar = Date.currentCalendar
        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        
        // 오늘 날짜 가져오기
        let today = calendar.startOfDay(for: Date())
        
        // 오늘 날짜에 시간, 분 설정
        return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: today) ?? Date()
    }
    
    // 사용자 시간대에 맞는 시간, 분 가져오기
    var localHour: Int {
        return Date.currentCalendar.component(.hour, from: self)
    }
    
    var localMinute: Int {
        return Date.currentCalendar.component(.minute, from: self)
    }
    
    // 사용자 시간대에 맞는 포맷팅된 시간 문자열
    func getLocalFormattedTime() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        formatter.timeZone = TimeZone.current
        return formatter.string(from: self)
    }
    
    // DatePicker에서 선택한 시간을 현지 시간으로 변환
    static func convertPickerDateToLocalTime(_ pickerDate: Date) -> Date {
        let calendar = Date.currentCalendar
        let hour = calendar.component(.hour, from: pickerDate)
        let minute = calendar.component(.minute, from: pickerDate)
        
        return Date.createLocalTime(hour: hour, minute: minute)
    }

}
