//
//  Refreshable.swift
//  FlowCrypt
//
//  Created by Yevhen Kyivskyi on 04.09.2021.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation

@MainActor
protocol Refreshable {
    func startRefreshing()
}
