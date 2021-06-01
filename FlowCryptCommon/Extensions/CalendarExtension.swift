//
//  CalendarExtension.swift
//  FlowCryptCommon
//
//  Created by Yevhen Kyivskyi on 01.06.2021.
//  Copyright © 2021 FlowCrypt Limited. All rights reserved.
//

import Foundation

public extension Calendar {
    
    func isDateInCurrentYear(_ date: Date) -> Bool {
        return self.isDate(date, equalTo: Date(), toGranularity: .year)
    }
}
