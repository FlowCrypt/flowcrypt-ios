//
//  ComposeViewController+Drafts.swift
//  FlowCrypt
//
//  Created by Ioan Moldovan on 4/6/22
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

// MARK: - Drafts
extension ComposeViewController {
    @objc internal func startDraftTimer() {
        saveDraftTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
            self?.saveDraftIfNeeded()
        }
        saveDraftTimer?.fire()
    }

    @objc internal func stopDraftTimer() {
        saveDraftTimer?.invalidate()
        saveDraftTimer = nil
        saveDraftIfNeeded()
    }

    private func shouldSaveDraft() -> Bool {
        // https://github.com/FlowCrypt/flowcrypt-ios/issues/975
        return false
//        let newDraft = ComposedDraft(email: email, input: input, contextToSend: contextToSend)
//        guard let oldDraft = composedLatestDraft else {
//            composedLatestDraft = newDraft
//            return true
//        }
//        let result = newDraft != oldDraft
//        composedLatestDraft = newDraft
//        return result
    }

    internal func saveDraftIfNeeded() {
        guard shouldSaveDraft() else { return }
        Task {
            do {
                let sendableMsg = try await composeMessageService.validateAndProduceSendableMsg(
                    senderEmail: selectedFromEmail,
                    input: input,
                    contextToSend: contextToSend,
                    includeAttachments: false
                )
                try await composeMessageService.encryptAndSaveDraft(message: sendableMsg, threadId: input.threadId)
            } catch {
                if case .promptUserToEnterPassPhraseForSigningKey(let keyPair) = error as? ComposeMessageError {
                    requestMissingPassPhraseWithModal(for: keyPair, isDraft: true)
                }
                if !(error is MessageValidationError) {
                    // no need to save or notify user if validation error
                    // for other errors show toast
                    // todo - should make sure that the toast doesn't hide the keyboard. Also should be toasted on top when keyboard open?
                    showToast("Error saving draft: \(error.errorMessage)")
                }
            }
        }
    }
}
