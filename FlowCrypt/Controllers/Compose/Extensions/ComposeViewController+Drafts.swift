//
//  ComposeViewController+Drafts.swift
//  FlowCrypt
//
//  Created by Ioan Moldovan on 4/6/22
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

let MAX_DRAFT_RETRY_ON_ERROR_COUNT = 10

// MARK: - Drafts
extension ComposeViewController {
    @objc func startDraftTimer(withFire: Bool = false) {
        guard saveDraftTimer == nil else { return }

        saveDraftTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.saveDraftIfNeeded()
        }

        if withFire {
            saveDraftTimer?.fire()
        }
    }

    @objc func stopDraftTimer(withSave: Bool = true) {
        guard saveDraftTimer != nil else { return }

        saveDraftTimer?.invalidate()
        saveDraftTimer = nil

        if withSave {
            saveDraftIfNeeded()
        }
    }

    private func createDraft() -> ComposedDraft? {
        let newDraft = ComposedDraft(
            input: input,
            contextToSend: contextToSend
        )

        guard let existingDraft = composedLatestDraft else {
            composedLatestDraft = newDraft
            return nil
        }

        return newDraft != existingDraft ? newDraft : nil
    }

    func saveDraftIfNeeded(handler: ((DraftSaveState) -> Void)? = nil, forceCreate: Bool = false) {
        if draftSaveRetryCount > 1, !shouldSaveCurrentDraft {
            // shouldSaveCurrentDraft is used for exponential backoff.
            // the first request failure retries after 5 seconds, the next retry is retried after 10 seconds...
            shouldSaveCurrentDraft = true
            return
        }
        guard let draft = createDraft() else {
            handler?(.cancelled)
            return
        }

        guard draftSaveRetryCount < MAX_DRAFT_RETRY_ON_ERROR_COUNT else {
            return
        }

        handler?(.saving(draft))

        Task {
            do {
                let shouldEncrypt = draft.input.type.info?.shouldEncrypt == true ||
                    contextToSend.hasRecipientsWithActivePubKey

                let sendableMsg = try await composeMessageHelper.createSendableMsg(
                    clientConfiguration: clientConfiguration,
                    input: draft.input,
                    contextToSend: draft.contextToSend,
                    shouldValidate: false,
                    shouldSign: false,
                    withPubKeys: shouldEncrypt
                )

                try await composeMessageHelper.saveDraft(
                    message: sendableMsg,
                    threadId: draft.input.threadId,
                    shouldEncrypt: shouldEncrypt,
                    forceCreate: forceCreate
                )

                composedLatestDraft = draft
                draftSaveRetryCount = 0
                handler?(.success(sendableMsg))
            } catch {
                if error.errorMessage.contains("Requested entity was not found.") {
                    // When draft entity was not found on gmail server, then create new draft
                    saveDraftIfNeeded(handler: handler, forceCreate: true)
                    return
                }
                shouldSaveCurrentDraft = false
                if !(error is MessageValidationError) {
                    // no need to save or notify user if validation error
                    // for other errors show toast
                    draftSaveRetryCount += 1
                    showToast(
                        "draft_error".localizeWithArguments(error.errorMessage),
                        position: .top,
                        view: self.navigationController?.navigationBar.superview,
                        maxHeightPercentage: 1.0
                    )
                }
                handler?(.error(error))
            }
        }
    }
}
