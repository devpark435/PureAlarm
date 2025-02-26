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
}
