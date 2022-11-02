//
//  ComposeViewController+Setup.swift
//  FlowCrypt
//
//  Created by Ioan Moldovan on 4/6/22
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import FlowCryptUI
import UIKit

// MARK: - Setup UI
extension ComposeViewController {
    func setupNavigationBar() {
        let deleteButton = NavigationBarItemsView.Input(
            image: UIImage(systemName: "trash"),
            accessibilityId: "aid-compose-delete"
        ) { [weak self] in
            self?.handleTrashTap()
        }
        let helpButton = NavigationBarItemsView.Input(
            image: UIImage(systemName: "questionmark.circle")
        ) { [weak self] in
            self?.handleInfoTap()
        }
        let attachmentButton = NavigationBarItemsView.Input(
            image: UIImage(systemName: "paperclip")
        ) { [weak self] in
            self?.handleAttachTap()
        }
        let sendButton = NavigationBarItemsView.Input(
            image: UIImage(systemName: "paperplane"),
            accessibilityId: "aid-compose-send"
        ) { [weak self] in
            self?.handleSendTap()
        }
        navigationItem.rightBarButtonItem = NavigationBarItemsView(
            with: [deleteButton, helpButton, attachmentButton, sendButton]
        )
    }

    func setupUI() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTableTap))

        node.do {
            $0.delegate = self
            $0.dataSource = self
            $0.view.contentInsetAdjustmentBehavior = .never
            $0.view.keyboardDismissMode = .interactive
            $0.view.backgroundView = UIView()
            $0.view.backgroundView?.addGestureRecognizer(tap)
        }

        updateView(newState: .main)
    }

    func fillDataFromInput() {
        guard let info = input.type.info else {
            didFinishSetup = true
            return
        }

        contextToSend.subject = info.subject
        addRecipients(from: info)

        if case .draft = input.type {
            processDraft(info: info)
        } else {
            reload(sections: Section.recipientsSections)
            didFinishSetup = true
        }
    }

    private func processDraft(info: ComposeMessageInput.MessageQuoteInfo) {
        composeMessageService.fetchMessageIdentifier(info: info)

        guard let id = info.id else {
            didFinishSetup = true
            return
        }

        Task {
            let message = try await messageService.fetchMessage(identifier: id, folder: "")
            let text = message.body.text

            if text.isPgp {
                await decodeDraft(text: text)
            } else {
                contextToSend.message = text
                didFinishSetup = true
            }
        }
    }

    private func addRecipients(from info: ComposeMessageInput.MessageQuoteInfo) {
        guard contextToSend.recipients.isEmpty else { return }

        for recipient in info.recipients {
            add(recipient: recipient, type: .to)
        }

        for recipient in info.ccRecipients {
            add(recipient: recipient, type: .cc)
        }

        for recipient in info.bccRecipients {
            add(recipient: recipient, type: .bcc)
        }

        if info.ccRecipients.isNotEmpty || info.bccRecipients.isNotEmpty {
            shouldShowAllRecipientTypes.toggle()
        }
    }

    private func decodeDraft(text: String) async {
        do {
            let decrypted = try await messageService.decrypt(
                text: text,
                userEmail: appContext.user.email,
                isUsingKeyManager: appContext.clientConfigurationService.configuration.isUsingKeyManager
            )
            contextToSend.message = decrypted
            didFinishSetup = true
            reload(sections: Section.recipientsSections + [.compose])
        } catch {
            if case let .missingPassPhrase(keyPair) = error as? MessageServiceError, let keyPair {
                requestMissingPassPhraseWithModal(for: keyPair, isDraft: true)
            } else {
                handle(error: error)
            }
        }
    }
}

// MARK: - Search
extension ComposeViewController {
    func setupSearch() {
        search
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates()
            .map { [weak self] query in
                if query.isEmpty {
                    self?.updateView(newState: .main)
                }
                return query
            }
            .sink(receiveValue: { [weak self] in
                guard $0.isNotEmpty else { return }
                self?.searchEmail(with: $0)
            })
            .store(in: &cancellable)
    }
}

// MARK: - NavigationChildController
extension ComposeViewController: NavigationChildController {
    func handleBackButtonTap() {
        stopDraftTimer(withSave: false)

        saveDraftIfNeeded { [weak self] state in
            guard let self else { return }

            switch state {
            case .cancelled:
                self.handleUpdateAction()
            case let .error(error):
                self.showToast("draft_error".localizeWithArguments(error.errorMessage))
            case .success:
                self.handleUpdateAction()
                self.showToast("draft_saved".localized, duration: 1.0)
            case .saving:
                self.showToast("draft_saving".localized, duration: 10.0)
            }
        }

        navigationController?.popViewController(animated: true)
    }

    private func handleUpdateAction() {
        guard var messageIdentifier = composeMessageService.messageIdentifier else { return }
        messageIdentifier.draftMessageId = input.type.info?.id
        handleAction?(.update(messageIdentifier))
    }
}
