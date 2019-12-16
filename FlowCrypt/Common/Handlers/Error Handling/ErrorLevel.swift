//
//  ErrorLevel.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 12/16/19.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import UIKit

enum ErrorLevel {
    /// handle errors from view controllers
    case viewController(Error, UIViewController)
    /// handle specific errors caused by some layers of logic
    case dataError(Error)
}
