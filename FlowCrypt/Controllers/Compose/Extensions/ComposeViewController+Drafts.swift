//
//  ComposeViewController+Drafts.swift
//  FlowCrypt
//
//  Created by Ioan Moldovan on 4/6/22
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

// MARK: - Drafts
extension ComposeViewController {
    @objc func startDraftTimer() {
        saveDraftTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.saveDraftIfNeeded()
        }
        saveDraftTimer?.fire()
    }

    @objc func stopDraftTimer() {
        saveDraftTimer?.invalidate()
        saveDraftTimer = nil
        saveDraftIfNeeded()
    }

    private func shouldSaveDraft() -> Bool {
        let newDraft = ComposedDraft(
            input: input,
            contextToSend: contextToSend
        )

        if let existingDraft = composedLatestDraft {
            let draftHasChanges = newDraft != existingDraft
            self.composedLatestDraft = newDraft
            return draftHasChanges
        } else { // save initial draft
            composedLatestDraft = newDraft
            return false
        }
    }

    // TODO: Better naming
    func saveDraftIfNeeded(isForceSave: Bool = false) {
        guard isForceSave || shouldSaveDraft() else { return }

        Task {
            do {
                let sendableMsg = try await composeMessageService.validateAndProduceSendableMsg(
                    input: input,
                    contextToSend: contextToSend,
                    isDraft: true
                )
                try await composeMessageService.encryptAndSaveDraft(message: sendableMsg, threadId: input.threadId)
            } catch {
                if case .promptUserToEnterPassPhraseForSigningKey(let keyPair) = error as? ComposeMessageError {
                    signingKeyWithMissingPassphrase = keyPair
                    reload(sections: [.passphrase])
                } else if !(error is MessageValidationError) {
                    // no need to save or notify user if validation error
                    // for other errors show toast
                    // todo - should make sure that the toast doesn't hide the keyboard. Also should be toasted on top when keyboard open?
                    showToast("Error saving draft: \(error.errorMessage)")
                }
            }
        }
    }
}
