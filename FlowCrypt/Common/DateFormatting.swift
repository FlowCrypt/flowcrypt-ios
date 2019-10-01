//
//  DateFormatting.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 01.10.2019.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import Foundation

extension DateFormatter {
    func formatDate(_ date: Date) -> String {
        let dateFormater = DateFormatter()
        if Calendar.current.isDateInToday(date) {
            dateFormater.dateFormat = "h:mm a"
        }
        else {
            dateFormater.dateFormat = "dd MMM"
        }
        return dateFormater.string(from: date)
    }
}
