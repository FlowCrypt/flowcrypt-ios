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
        case centered(UIView)
        case sourceView(UIView)
    }
    
    @discardableResult
    func popoverPresentation(style: PopoverPresentationStyle) -> UIAlertController {
        switch style {
        case .centered(let view):
            popoverPresentationController?.centeredPresentation(in: view)
        case .sourceView(let view):
            popoverPresentationController?.sourceView = view
        }
        return self
    }
}
