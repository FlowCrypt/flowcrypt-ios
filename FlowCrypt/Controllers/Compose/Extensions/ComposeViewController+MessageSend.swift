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
    func validateAndSendMessage(shouldSendPlainMessage: Bool = false) async throws {
        guard checkIfAllRecipientsAreValid() else { return }

        guard shouldSendPlainMessage || contextToSend.hasMessagePasswordIfNeeded else {
            throw MessageValidationError.noPubRecipients
        }

        showSendingSpinner()
        evaluateSelectedRecipients()

        let messageIdentifier = try await sendMessage(isPlain: shouldSendPlainMessage)
        handleAction?(.sent(messageIdentifier))

        handleSuccessfullySentMessage(isEncrypted: !shouldSendPlainMessage)
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

    private func sendMessage(isPlain: Bool) async throws -> MessageIdentifier {
        let sendableMsg = try await composeMessageHelper.createSendableMsg(
            input: input,
            contextToSend: contextToSend,
            shouldSign: !isPlain,
            withPubKeys: !isPlain
        )

        UIApplication.shared.isIdleTimerDisabled = true

        let identifier = try await composeMessageHelper.composeAndSend(
            message: sendableMsg,
            threadId: input.threadId,
            isPlain: isPlain
        )

        UIApplication.shared.isIdleTimerDisabled = false

        return MessageIdentifier(
            draftId: input.type.info?.id,
            threadId: Identifier(stringId: input.threadId),
            messageId: identifier
        )
    }

    private func handleSuccessfullySentMessage(isEncrypted: Bool) {
        showToast(input.successfullySentToast(isEncrypted: isEncrypted))
        navigationController?.popViewController(animated: true)
    }
}
