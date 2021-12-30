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
    internal func prepareSigningKey() async throws -> PrvKeyInfo {
        guard let signingKey = try await appContext.keyService.getSigningKey(email: appContext.user.email) else {
            throw AppErr.general("None of your private keys have your user id \"\(email)\". Please import the appropriate key.")
        }

        guard let existingPassPhrase = signingKey.passphrase else {
            return signingKey.copy(with: try await self.requestMissingPassPhraseWithModal(for: signingKey))
        }

        return signingKey.copy(with: existingPassPhrase)
    }

    internal func requestMissingPassPhraseWithModal(for signingKey: PrvKeyInfo) async throws -> String {
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String, Error>) in
            let alert = AlertsFactory.makePassPhraseAlert(
                onCancel: {
                    return continuation.resume(throwing: AppErr.user("Passphrase is required for message signing"))
                },
                onCompletion: { [weak self] passPhrase in
                    guard let self = self else {
                        return continuation.resume(throwing: AppErr.nilSelf)
                    }
                    Task<Void, Never> {
                        do {
                            let matched = try await self.handlePassPhraseEntry(passPhrase, for: signingKey)
                            if matched {
                                return continuation.resume(returning: passPhrase)
                            } else {
                                throw AppErr.user("This pass phrase did not match your signing private key")
                            }
                        } catch {
                            return continuation.resume(throwing: error)
                        }
                    }
                }
            )
            present(alert, animated: true, completion: nil)
        }
    }

    internal func handlePassPhraseEntry(_ passPhrase: String, for signingKey: PrvKeyInfo) async throws -> Bool {
        // since pass phrase was entered (an inconvenient thing for user to do),
        //  let's find all keys that match and save the pass phrase for all
        let allKeys = try await appContext.keyService.getPrvKeyInfo(email: appContext.user.email)
        guard allKeys.isNotEmpty else {
            // tom - todo - nonsensical error type choice https://github.com/FlowCrypt/flowcrypt-ios/issues/859
            //   I copied it from another usage, but has to be changed
            throw KeyServiceError.retrieve
        }
        let matchingKeys = try await self.keyMethods.filterByPassPhraseMatch(keys: allKeys, passPhrase: passPhrase)
        // save passphrase for all matching keys
        try appContext.passPhraseService.savePassPhrasesInMemory(passPhrase, for: matchingKeys)
        // now figure out if the pass phrase also matched the signing prv itself
        let matched = matchingKeys.first(where: { $0.fingerprints.first == signingKey.fingerprints.first })
        return matched != nil// true if the pass phrase matched signing key
    }

    internal func sendMessage(_ signingKey: PrvKeyInfo) async throws {
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
            contextToSend: self.contextToSend,
            signingPrv: signingKey
        )
        UIApplication.shared.isIdleTimerDisabled = true
        try await composeMessageService.encryptAndSend(
            message: sendableMsg,
            threadId: input.threadId
        )
        handleSuccessfullySentMessage()
    }

    internal func handle(error: Error) {
        UIApplication.shared.isIdleTimerDisabled = false
        hideSpinner()
        navigationItem.rightBarButtonItem?.isEnabled = true

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
