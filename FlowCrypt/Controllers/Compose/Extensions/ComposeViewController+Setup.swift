//
//  ComposeViewController+Setup.swift
//  FlowCrypt
//
//  Created by Ioan Moldovan on 4/6/22
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import UIKit
import FlowCryptUI

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

        if case .draft = input.type, let messageId = input.type.info?.rfc822MsgId {
            Task {
                try await composeMessageService.fetchDraftIdentifier(for: messageId)
            }
        }

        contextToSend.subject = info.subject
        addRecipients(from: info)

        if input.isPgp {
            decodeDraft(from: info)
        } else {
            if case .draft = input.type {
                contextToSend.message = input.text
            }
            reload(sections: Section.recipientsSections)
            didFinishSetup = true
        }
    }

    private func addRecipients(from info: ComposeMessageInput.MessageQuoteInfo) {
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

    private func decodeDraft(from info: ComposeMessageInput.MessageQuoteInfo) {
        let message = Message(
            identifier: .random,
            date: info.sentDate,
            sender: info.sender,
            subject: info.subject,
            size: nil,
            labels: [],
            attachmentIds: [],
            body: .init(text: info.text, html: nil)
        )

        Task {
            do {
                let processedMessage = try await messageService.decryptAndProcess(
                    message: message,
                    onlyLocalKeys: false,
                    userEmail: appContext.user.email,
                    isUsingKeyManager: appContext.clientConfigurationService.configuration.isUsingKeyManager
                )
                contextToSend.message = processedMessage.text
                setupTextNode()
                reload(sections: [.compose])
                didFinishSetup = true
            } catch {
                if case .missingPassPhrase(let keyPair) = error as? MessageServiceError, let keyPair = keyPair {
                    requestMissingPassPhraseWithModal(for: keyPair, isDraft: true)
                    return
                } else {
                    handle(error: error)
                }
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
            .map { [weak self] query -> String in
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

        saveDraftIfNeeded(withAlert: true) { [weak self] error in
            guard let self = self else { return }

            if let error = error {
                self.handle(error: error)
            } else {
                if var messageIdentifier = self.composeMessageService.messageIdentifier {
                    messageIdentifier.draftMessageId = self.input.type.info?.id
                    self.handleAction?(.update(messageIdentifier))
                }
                self.navigationController?.popViewController(animated: true)
            }
        }
    }
}
