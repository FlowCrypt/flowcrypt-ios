//
//  UIAlertControllerExtensions.swift
//  FlowCryptCommon
//
//  Created by Anton Kharchevskyi on 07.01.2022
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import UIKit

public extension UIAlertController {
    enum PopoverPresentationStyle {
        case centred(UIView)
        case sourceView(UIView)
    }

    @discardableResult
    func popoverPresentation(style: PopoverPresentationStyle) -> UIAlertController {
        switch style {
        case let .centred(view):
            popoverPresentationController?.centredPresentation(in: view)
        case let .sourceView(view):
            popoverPresentationController?.sourceView = view
        }
        return self
    }
}
