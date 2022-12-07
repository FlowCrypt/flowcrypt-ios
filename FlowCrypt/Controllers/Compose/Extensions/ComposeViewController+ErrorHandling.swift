//
//  ComposeViewController+ErrorHandling.swift
//  FlowCrypt
//
//  Created by Roma Sosnovsky on 14/09/22
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import UIKit

// MARK: - Error handling
extension ComposeViewController {
    func requestMissingPassPhraseWithModal(for signingKey: Keypair, isDraft: Bool = false) {
        let alert = alertsFactory.makePassPhraseAlert(
            onCancel: { [weak self] in
                self?.navigationController?.popViewController(animated: true)
            },
            onCompletion: { [weak self] passPhrase in
                guard let self else { return }

                Task {
                    do {
                        let matched = try await self.composeMessageHelper.handlePassPhraseEntry(
                            passPhrase,
                            for: signingKey
                        )

                        if matched {
                            self.handleMatchedPassphrase(isDraft: isDraft)
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

    private func handleMatchedPassphrase(isDraft: Bool) {
        guard isDraft else {
            handleSendTap()
            return
        }

        guard didFinishSetup else {
            fillDataFromInput()
            return
        }

        saveDraftIfNeeded()
    }

    func handle(error: Error) {
        reEnableSendButton()

        if case let .missingPassPhrase(keyPair) = error as? ComposeMessageError {
            requestMissingPassPhraseWithModal(for: keyPair)
            return
        }

        let hideSpinnerAnimationDuration: TimeInterval = 1
        DispatchQueue.main.asyncAfter(deadline: .now() + hideSpinnerAnimationDuration) { [weak self] in
            guard let self else { return }

            switch error {
            case MessageValidationError.noPubRecipients:
                guard self.isMessagePasswordSupported else {
                    self.showPlainMessageConfirmationAlert()
                    return
                }

                if Bundle.isEnterprise {
                    self.setMessagePassword()
                } else {
                    self.showPlainMessageAlert()
                }
            case MessageValidationError.notUniquePassword,
                 MessageValidationError.subjectContainsPassword,
                 MessageValidationError.weakPassword:
                self.showAlert(message: error.errorMessage)
            default:
                self.showAlert(message: "compose_error".localized + "\n\n" + error.errorMessage)
            }
        }
    }

    private func showPlainMessageConfirmationAlert() {
        showAlertWithAction(
            title: "compose_message_encryption".localized,
            message: "compose_plain_message_confirmation".localized,
            actionButtonTitle: "compose_send_unencrypted".localized,
            actionAccessibilityIdentifier: "aid-compose-send-plain",
            onAction: { [weak self] _ in self?.handleSendTap(shouldSendPlainMessage: true) }
        )
    }

    private func showPlainMessageAlert() {
        showAlertWithAction(
            title: "compose_message_encryption".localized,
            message: "compose_plain_message_alert".localized,
            cancelButtonTitle: "compose_add_message_password".localized,
            actionButtonTitle: "compose_send_unencrypted".localized,
            actionAccessibilityIdentifier: "aid-compose-send-plain",
            onAction: { [weak self] _ in self?.handleSendTap(shouldSendPlainMessage: true) },
            onCancel: { [weak self] _ in self?.setMessagePassword() }
        )
    }

    private func reEnableSendButton() {
        UIApplication.shared.isIdleTimerDisabled = false
        startDraftTimer()
        hideSpinner()
        navigationItem.rightBarButtonItem?.isEnabled = true
    }
}
