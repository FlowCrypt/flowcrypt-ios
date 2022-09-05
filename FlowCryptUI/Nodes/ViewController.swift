//
//  ViewController.swift
//  FlowCryptUI
//
//  Created by Anton Kharchevskyi on 11.01.2022
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import AsyncDisplayKit
import FlowCryptCommon

@MainActor
open class ViewController: ASDKViewController<ASDisplayNode> {
    override open func viewDidLoad() {
        super.viewDidLoad()
        Logger.nested(Self.self).logDebug("View did load")
    }
}
