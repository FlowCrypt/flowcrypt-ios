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
    func requestMissingPassPhraseWithModal(for signingKey: Keypair, isDraft: Bool = false, withDiscard: Bool = false) {
        let alert = alertsFactory.makePassPhraseAlert(
            onCancel: { [weak self] in
                guard let self = self else { return }
                if !withDiscard {
                    self.handle(error: ComposeMessageError.passPhraseRequired)
                } else {
                    self.navigationController?.popViewController(animated: true)
                }
            },
            onCompletion: { [weak self] passPhrase in
                guard let self = self else { return }

                Task<Void, Never> {
                    do {
                        let matched = try await self.composeMessageService.handlePassPhraseEntry(
                            passPhrase,
                            for: signingKey
                        )
                        // TODO: make more readable
                        if matched {
                            if isDraft {
                                if self.didFinishSetup {
                                    if withDiscard {
                                        self.handleBackButtonTap()
                                    } else {
                                        self.saveDraftIfNeeded()
                                    }
                                } else {
                                    self.fillDataFromInput()
                                }
                            } else {
                                self.handleSendTap()
                            }
                            self.reload(sections: [.passphrase])
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

    func handle(error: Error) {
        reEnableSendButton()

        if case .missingPassPhrase(let keyPair) = error as? ComposeMessageError {
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

    private func reEnableSendButton() {
        UIApplication.shared.isIdleTimerDisabled = false
        startDraftTimer()
        hideSpinner()
        navigationItem.rightBarButtonItem?.isEnabled = true
    }
}
