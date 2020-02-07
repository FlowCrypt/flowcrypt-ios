//
//  LaunchContext.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 07/02/2020.
//  Copyright © 2020 FlowCrypt Limited. All rights reserved.
//

import Foundation

struct LaunchContext {
    var window: UIWindow?
    let aplication: UIApplication
    let launchOptions: [UIApplication.LaunchOptionsKey: Any]?
}
