//
//  ComposeViewController+TapActions.swift
//  FlowCrypt
//
//  Created by Ioan Moldovan on 4/6/22
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

// MARK: - Handle actions
extension ComposeViewController {
    internal func handleInfoTap() {
        showToast("Please email us at human@flowcrypt.com for help")
    }

    internal func handleAttachTap() {
        openAttachmentsInputSourcesSheet()
    }

    internal func handleSendTap() {
        Task {
            do {
                guard contextToSend.hasMessagePasswordIfNeeded else {
                    throw MessageValidationError.noPubRecipients
                }

                let key = try await prepareSigningKey()
                try await sendMessage(key)
            } catch {
                handle(error: error)
            }
        }
    }

    @objc internal func handleTableTap() {
        if case .searchEmails = state,
           let selectedRecipientType = selectedRecipientType,
           let textField = recipientsTextField(type: selectedRecipientType),
           textField.text.isValidEmail {
            handleEndEditingAction(with: textField.text, for: selectedRecipientType)
        }
    }
}
