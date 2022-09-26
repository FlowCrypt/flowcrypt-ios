//
//  ComposeViewController+TapActions.swift
//  FlowCrypt
//
//  Created by Ioan Moldovan on 4/6/22
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

// MARK: - Handle actions
extension ComposeViewController {
    func handleInfoTap() {
        showToast("Please email us at human@flowcrypt.com for help")
    }

    func handleAttachTap() {
        openAttachmentsInputSourcesSheet()
    }

    func handleSendTap() {
        Task {
            do {
                guard contextToSend.hasMessagePasswordIfNeeded else {
                    throw MessageValidationError.noPubRecipients
                }

                try await sendMessage()
            } catch {
                handle(error: error)
            }
        }
    }

    func handleTrashTap() {
        showAlertWithAction(
            title: "draft_delete_confirmation".localized,
            message: nil,
            actionButtonTitle: "delete".localized,
            actionStyle: .destructive,
            onAction: { [weak self] _ in
                guard let self = self else { return }
                Task {
                    do {
                        let messageId = self.input.type.info?.id
                        try await self.composeMessageService.deleteDraft(messageId: messageId)

                        if let messageId = messageId {
                            let identifier = MessageIdentifier(
                                threadId: Identifier(stringId: self.input.type.info?.threadId),
                                messageId: messageId
                            )
                            self.handleAction?(.delete(identifier))
                        }

                        self.navigationController?.popViewController(animated: true)
                    } catch {
                        self.handle(error: error)
                    }
                }
            }
        )
    }

    @objc func handleTableTap() {
        if case .searchEmails = state,
           let selectedRecipientType = selectedRecipientType,
           let textField = recipientsTextField(type: selectedRecipientType),
           textField.text.isValidEmail {
            handleEndEditingAction(with: textField.text, for: selectedRecipientType)
        }
    }
}
