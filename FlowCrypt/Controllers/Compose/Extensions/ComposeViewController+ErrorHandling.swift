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
        alertsFactory.makePassPhraseAlert(
            viewController: self,
            onCancel: { [weak self] in
                self?.navigationController?.popViewController(animated: true)
            },
            onCompletion: { [weak self] passPhrase in
                guard let self else { return }

                Task {
                    do {
                        self.showSpinner()
                        let matched = try await self.composeMessageHelper.handlePassPhraseEntry(
                            passPhrase,
                            for: signingKey
                        )

                        if matched {
                            self.alertsFactory.passphraseCheckSucceed()
                            self.handleMatchedPassphrase(isDraft: isDraft)
                        } else {
                            self.alertsFactory.passphraseCheckFailed()
                            self.handle(error: ComposeMessageError.passPhraseNoMatch)
                        }
                    } catch {
                        self.hideSpinner()
                        self.handle(error: error)
                    }
                }
            }
        )
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

        switch error {
        case MessageValidationError.noPubRecipients,
             MessageValidationError.revokedKeyRecipients,
             MessageValidationError.expiredKeyRecipients,
             MessageValidationError.notUsableForEncryptionKeyRecipients:
            processSendMessageWithNoValidKeys(error: error)
        case MessageValidationError.noUsableAccountKeys,
             KeypairError.noAccountKeysAvailable:
            if isKeyUpdatedFromEKM {
                showAlert(message: "compose_error".localized + "\n\n" + error.errorMessage)
                isKeyUpdatedFromEKM = false // Set to false so that it will be fetched next time
            } else {
                refreshEKMAndProceed(error: error)
            }
        case let MessageValidationError.messagePasswordDisallowed(error):
            alertsFactory.makeCustomAlert(viewController: self, message: error)
        case MessageValidationError.notUniquePassword,
             MessageValidationError.subjectContainsPassword,
             MessageValidationError.weakPassword:
            showAlert(message: error.errorMessage)
        default:
            showAlert(message: "compose_error".localized + "\n\n" + error.errorMessage)
        }
    }

    private func refreshEKMAndProceed(error: Error) {
        Task {
            isKeyUpdatedFromEKM = true
            await ekmVcHelper.refreshKeysFromEKMIfNeeded(in: self, forceRefresh: true)
            handleSendTap()
        }
    }

    private func processSendMessageWithNoValidKeys(error: Error) {
        let alert = UIAlertController(
            title: "compose_message_encryption".localized,
            message: error.errorMessage,
            preferredStyle: .alert
        )
        let sendUnEncryptedAction = UIAlertAction(
            title: "compose_send_unencrypted".localized,
            style: .default,
            handler: { [weak self] _ in
                self?.handleSendTap(shouldSendPlainMessage: true)
            }
        )
        sendUnEncryptedAction.accessibilityIdentifier = "aid-compose-send-plain"
        let sendPasswordProtectedAction = UIAlertAction(
            title: "compose_add_message_password".localized,
            style: .default,
            handler: { [weak self] _ in
                self?.setMessagePassword()
            }
        )
        sendPasswordProtectedAction.accessibilityIdentifier = "aid-compose-send-message-password"
        let cancelAction = UIAlertAction(
            title: "cancel".localized,
            style: .cancel
        )
        cancelAction.accessibilityIdentifier = "aid-cancel-button"
        if !Bundle.isEnterprise {
            alert.addAction(sendUnEncryptedAction) // Disallow sending plain message for enterprise
        }
        if isMessagePasswordSupported {
            alert.addAction(sendPasswordProtectedAction)
        }
        alert.addAction(cancelAction)
        present(alert, animated: true, completion: nil)
    }

    private func reEnableSendButton() {
        UIApplication.shared.isIdleTimerDisabled = false
        startDraftTimer()
        hideSpinner()
        navigationItem.rightBarButtonItem?.isEnabled = true
    }
}
