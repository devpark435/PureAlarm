//
//  UIView+Extensions.swift
//  PureAlarm
//
//  Created by 박현렬 on 2/26/25.
//

import UIKit

extension UIView {
    func addSubviews(_ views: UIView...) {
        views.forEach { addSubview($0) }
    }
}
