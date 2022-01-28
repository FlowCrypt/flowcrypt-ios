//
//  UIPopoverPresentationControllerExtensions.swift
//  FlowCryptCommon
//
//  Created by Anton Kharchevskyi on 09.01.2022
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import UIKit

public extension UIPopoverPresentationController {
    func centredPresentation(in view: UIView) {
        sourceView = view
        sourceRect = .init(
            x: view.bounds.midX,
            y: view.bounds.midY,
            width: 0,
            height: 0
        )
        permittedArrowDirections = []
    }
}
