//
//  ComposeViewController+MessageSend.swift
//  FlowCrypt
//
//  Created by Ioan Moldovan on 4/6/22
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import UIKit
import FlowCryptCommon
import FlowCryptUI

// MARK: - Message Sending
extension ComposeViewController {
    internal func sendMessage() async throws {
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

        let sendableMsg = try await self.composeMessageService.validateAndProduceSendableMsg(
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

    internal func requestMissingPassPhraseWithModal(for signingKey: Keypair, isDraft: Bool = false) {
        let alert = AlertsFactory.makePassPhraseAlert(
            onCancel: {
                self.handle(error: ComposeMessageError.passPhraseRequired)
            },
            onCompletion: { [weak self] passPhrase in
                guard let self = self else {
                    return
                }
                Task<Void, Never> {
                    do {
                        let matched = try await self.composeMessageService.handlePassPhraseEntry(passPhrase, for: signingKey)
                        if matched {
                            if isDraft {
                                self.saveDraftIfNeeded()
                            } else {
                                self.handleSendTap()
                            }
                        } else {
                            self.handle(error: ComposeMessageError.passPhraseNoMatch)
                        }
                    } catch {
                        self.handle(error: error)
                    }
                }
            }
        )
        present(alert, animated: true, completion: nil)
    }

    internal func handle(error: Error) {
        UIApplication.shared.isIdleTimerDisabled = false
        hideSpinner()
        navigationItem.rightBarButtonItem?.isEnabled = true

        if case .promptUserToEnterPassPhraseForSigningKey(let keyPair) = error as? ComposeMessageError {
            requestMissingPassPhraseWithModal(for: keyPair)
            return
        }

        let hideSpinnerAnimationDuration: TimeInterval = 1
        DispatchQueue.main.asyncAfter(deadline: .now() + hideSpinnerAnimationDuration) { [weak self] in
            guard let self = self else { return }

            if self.isMessagePasswordSupported {
                switch error {
                case MessageValidationError.noPubRecipients:
                    self.setMessagePassword()
                case MessageValidationError.notUniquePassword,
                    MessageValidationError.subjectContainsPassword,
                    MessageValidationError.weakPassword:
                    self.showAlert(message: error.errorMessage)
                default:
                    self.showAlert(message: "compose_error".localized + "\n\n" + error.errorMessage)
                }
            } else {
                self.showAlert(message: "compose_error".localized + "\n\n" + error.errorMessage)
            }
        }
    }

    private func handleSuccessfullySentMessage() {
        UIApplication.shared.isIdleTimerDisabled = false
        hideSpinner()
        navigationItem.rightBarButtonItem?.isEnabled = true
        showToast(input.successfullySentToast)
        navigationController?.popViewController(animated: true)
    }
}
