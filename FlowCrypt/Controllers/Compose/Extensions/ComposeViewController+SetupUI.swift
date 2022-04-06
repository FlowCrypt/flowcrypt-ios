//
//  ComposeViewController+SetupUI.swift
//  FlowCrypt
//
//  Created by Ioan Moldovan on 4/6/22
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import UIKit
import FlowCryptUI

// MARK: - Setup UI
extension ComposeViewController {
    internal func setupNavigationBar() {
        navigationItem.rightBarButtonItem = NavigationBarItemsView(
            with: [
                NavigationBarItemsView.Input(
                    image: UIImage(named: "help_icn")
                ) { [weak self] in
                    self?.handleInfoTap()
                },
                NavigationBarItemsView.Input(
                    image: UIImage(named: "paperclip")
                ) { [weak self] in
                    self?.handleAttachTap()
                },
                NavigationBarItemsView.Input(
                    image: UIImage(named: "android-send"),
                    accessibilityId: "aid-compose-send"
                ) { [weak self] in
                    self?.handleSendTap()
                }
            ]
        )
    }

    internal func setupUI() {
        node.do {
            $0.delegate = self
            $0.dataSource = self
            $0.view.contentInsetAdjustmentBehavior = .never
            $0.view.keyboardDismissMode = .interactive
        }

        updateState(with: .main)
    }

    internal func setupQuote() {
        guard input.isQuote else { return }

        for recipient in input.quoteRecipients {
            evaluateMessage(recipient: recipient, type: .to)
        }

        for recipient in input.quoteCCRecipients {
            evaluateMessage(recipient: recipient, type: .cc)
        }

        if input.quoteCCRecipients.isNotEmpty {
            shouldShowAllRecipientTypes.toggle()
        }
    }
}
