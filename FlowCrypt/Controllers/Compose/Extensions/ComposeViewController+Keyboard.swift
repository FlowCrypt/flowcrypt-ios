//
//  ComposeViewController+Keyboard.swift
//  FlowCrypt
//
//  Created by Ioan Moldovan on 4/6/22
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import FlowCryptUI
import UIKit

// MARK: - Keyboard
extension ComposeViewController {
    func observerAppStates() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(startDraftTimer),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(stopDraftTimer),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
    }
}
