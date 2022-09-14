//
//  ComposeViewController+MessageSend.swift
//  FlowCrypt
//
//  Created by Ioan Moldovan on 4/6/22
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import UIKit
import FlowCryptUI

// MARK: - Message Sending
extension ComposeViewController {
    func sendMessage() async throws {
        view.endEditing(true)
        navigationItem.rightBarButtonItem?.isEnabled = false

        let spinnerTitle = contextToSend.attachments.isEmpty ? "sending_title" : "encrypting_title"
        showSpinner(spinnerTitle.localized)

        let selectedRecipients = contextToSend.recipients.filter(\.state.isSelected)
        for selectedRecipient in selectedRecipients {
            evaluate(recipient: selectedRecipient)
        }

        // TODO: - fix for spinner
        // https://github.com/FlowCrypt/flowcrypt-ios/issues/291
        try await Task.sleep(nanoseconds: 100 * 1_000_000) // 100ms

        let sendableMsg = try await composeMessageService.validateAndProduceSendableMsg(
            input: self.input,
            contextToSend: self.contextToSend
        )
        UIApplication.shared.isIdleTimerDisabled = true
        try await composeMessageService.encryptAndSend(
            message: sendableMsg,
            threadId: input.threadId
        )
        handleSuccessfullySentMessage()
    }

    private func handleSuccessfullySentMessage() {
        showToast(input.successfullySentToast)
        navigationController?.popViewController(animated: true)
    }
}
