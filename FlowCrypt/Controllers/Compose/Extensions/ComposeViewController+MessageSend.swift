//
//  ComposeViewController+MessageSend.swift
//  FlowCrypt
//
//  Created by Ioan Moldovan on 4/6/22
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import FlowCryptUI
import UIKit

// MARK: - Message Sending
extension ComposeViewController {
    func validateAndSendMessage() async throws {
        guard checkIfAllRecipientsAreValid() else { return }

        showSendingSpinner()
        evaluateSelectedRecipients()

        // TODO: - fix for spinner
        // https://github.com/FlowCrypt/flowcrypt-ios/issues/291
        try await Task.sleep(nanoseconds: 100 * 1_000_000) // 100ms

        let messageIdentifier = try await sendMessage()
        handleAction?(.sent(messageIdentifier))

        handleSuccessfullySentMessage()
    }

    private func checkIfAllRecipientsAreValid() -> Bool {
        view.endEditing(true)

        if let selectedRecipientType,
           let text = recipientsTextField(type: selectedRecipientType)?.text,
           !text.isEmpty {
            return false
        }

        return true
    }

    private func showSendingSpinner() {
        navigationItem.rightBarButtonItem?.isEnabled = false

        let spinnerTitle = contextToSend.attachments.isEmpty ? "sending_title" : "encrypting_title"
        showSpinner(spinnerTitle.localized)
    }

    private func evaluateSelectedRecipients() {
        let selectedRecipients = contextToSend.recipients.filter(\.state.isSelected)
        for selectedRecipient in selectedRecipients {
            evaluate(recipient: selectedRecipient)
        }
    }

    private func sendMessage() async throws -> MessageIdentifier {
        let sendableMsg = try await composeMessageService.validateAndProduceSendableMsg(
            input: input,
            contextToSend: contextToSend
        )

        UIApplication.shared.isIdleTimerDisabled = true

        let identifier = try await composeMessageService.encryptAndSend(
            message: sendableMsg,
            threadId: input.threadId
        )

        UIApplication.shared.isIdleTimerDisabled = false

        return MessageIdentifier(
            draftId: input.type.info?.id,
            threadId: Identifier(stringId: input.threadId),
            messageId: identifier
        )
    }

    private func handleSuccessfullySentMessage() {
        showToast(input.successfullySentToast)
        navigationController?.popViewController(animated: true)
    }
}
