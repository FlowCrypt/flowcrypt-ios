//
//  NavigationChildController.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 12.07.2021.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import UIKit

protocol NavigationChildController {
    var navigationItem: UINavigationItem { get }
    var shouldShowBackButton: Bool { get }
    func handleBackButtonTap()
}

extension NavigationChildController where Self: UIViewController {
    var shouldShowBackButton: Bool { true }
    func handleBackButtonTap() {}
}
