//
//  DateFormattingExtensions.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 01.10.2019.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation

public extension DateFormatter {
    func formatDate(_ date: Date) -> String {
        let dateFormater = DateFormatter()
        if Calendar.current.isDateInToday(date) {
            dateFormater.dateFormat = "HH:mm"
        } else if Calendar.current.isDateInCurrentYear(date) {
            dateFormater.dateFormat = "MMM dd"
        } else {
            dateFormater.dateFormat = "MMM dd, yyyy"
        }
        return dateFormater.string(from: date)
    }
}
