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
            image: UIImage(systemName: "trash")
        ) { [weak self] in
            // TODO:
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
        guard let info = input.type.info else { return }

        contextToSend.subject = info.subject

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

        if input.isPgp {
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
                let processedMessage = try await messageService.decryptAndProcess(
                    message: message,
                    onlyLocalKeys: false,
                    userEmail: appContext.user.email,
                    isUsingKeyManager: appContext.clientConfigurationService.configuration.isUsingKeyManager
                )
                contextToSend.message = processedMessage.text
                reload(sections: [.compose])
            }
        } else {
            contextToSend.message = info.text
        }
    }

    func setupNodes() {
        setupTextNode()
        setupSubjectNode()
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
