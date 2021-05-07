//
//  main.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 18.10.2019.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import Foundation
import UIKit

autoreleasepool {
    if ProcessInfo().arguments.contains(AppReset.reset.rawValue) {
        AppReset.resetKeychain()
        AppReset.resetUserDefaults()
    }

    UIApplicationMain(
        CommandLine.argc,
        CommandLine.unsafeArgv,
        nil,
        NSStringFromClass(AppDelegate.self)
    )
}
