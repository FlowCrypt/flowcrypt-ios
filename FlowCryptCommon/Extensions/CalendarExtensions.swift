//
//  CalendarExtensions.swift
//  FlowCryptCommon
//
//  Created by Yevhen Kyivskyi on 01.06.2021.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation

public extension Calendar {
    func isDateInCurrentYear(_ date: Date) -> Bool {
        self.isDate(date, equalTo: Date(), toGranularity: .year)
    }
}
