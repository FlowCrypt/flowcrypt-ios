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

    func handleSendTap(shouldSendPlainMessage: Bool = false) {
        stopDraftTimer(withSave: false)

        Task {
            do {
                try await validateAndSendMessage(shouldSendPlainMessage: shouldSendPlainMessage)
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
                self?.deleteDraft()
            }
        )
    }

    private func deleteDraft() {
        stopDraftTimer(withSave: false)

        Task {
            do {
                try await composeMessageService.deleteDraft()

                if let messageIdentifier = composeMessageService.messageIdentifier {
                    composeMessageService.messageIdentifier = nil
                    handleAction?(.delete(messageIdentifier))
                }

                showToast("draft_deleted".localized, duration: 1.0)
                navigationController?.popViewController(animated: true)
            } catch {
                handle(error: error)
            }
        }
    }

    @objc func handleTableTap() {
        if case .searchEmails = state,
           let selectedRecipientType,
           let textField = recipientsTextField(type: selectedRecipientType),
           textField.text.isValidEmail {
            handleEndEditingAction(with: textField.text, for: selectedRecipientType)
        }
    }
}
