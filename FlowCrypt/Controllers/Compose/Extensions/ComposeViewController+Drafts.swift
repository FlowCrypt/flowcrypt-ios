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

    private func createDraft() -> ComposedDraft? {
        let newDraft = ComposedDraft(
            input: input,
            contextToSend: contextToSend
        )

        if let existingDraft = composedLatestDraft {
            return newDraft != existingDraft ? newDraft : nil
        } else { // save initial draft
            composedLatestDraft = newDraft
            return nil
        }
    }

    func saveDraftIfNeeded(withAlert: Bool = false, completion: ((Error?) -> Void)? = nil) {
        guard let draft = createDraft() else {
            completion?(nil)
            return
        }

        Task {
            do {
                let sendableMsg = try await composeMessageService.validateAndProduceSendableMsg(
                    input: draft.input,
                    contextToSend: draft.contextToSend,
                    isDraft: true
                )

                try await composeMessageService.encryptAndSaveDraft(
                    message: sendableMsg,
                    threadId: draft.input.threadId
                )

                composedLatestDraft = draft
                completion?(nil)
            } catch {
                if case .missingPassPhrase(let keyPair) = error as? ComposeMessageError {
                    signingKeyWithMissingPassphrase = keyPair
                    reload(sections: [.passphrase])
                } else if !(error is MessageValidationError) {
                    // no need to save or notify user if validation error
                    // for other errors show toast
                    // todo - should make sure that the toast doesn't hide the keyboard. Also should be toasted on top when keyboard open?
                    showToast("Error saving draft: \(error.errorMessage)")
                }
                completion?(error)
            }
        }
    }
}
