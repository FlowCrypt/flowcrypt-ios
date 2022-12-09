//
//  ThreadDetailsViewController+MessageActionsHandler.swift
//  FlowCrypt
//
//  Created by Roma Sosnovsky on 01.11.2022
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation

extension ThreadDetailsViewController: MessageActionsHandler {

    private func handle(action: MessageAction, error: Error? = nil) {
        hideSpinner()

        if let error {
            logger.logError("\(action.error ?? "Error: ") \(error)")
            showAlert(message: error.errorMessage)
            return
        }

        onComplete(action, inboxItem)
        navigationController?.popViewController(animated: true)
    }

    func permanentlyDelete() {
        logger.logInfo("permanently delete")
        perform(action: .permanentlyDelete)
    }

    func moveToTrash(with trashPath: String) {
        logger.logInfo("move to trash \(trashPath)")
        perform(action: .moveToTrash)
    }

    func handleArchiveTap() {
        perform(action: .archive)
    }

    func handleMoveToInboxTap() {
        perform(action: .moveToInbox)
    }

    func handleMarkUnreadTap() {
        let messages = input.filter(\.isExpanded).map(\.rawMessage)

        guard messages.isNotEmpty else { return }

        perform(action: .markAsRead(false))
    }

    func perform(action: MessageAction) {
        Task {
            do {
                showSpinner()

                switch action {
                case .archive:
                    try await threadOperationsApiClient.archive(
                        messagesIds: inboxItem.messages.map(\.identifier),
                        in: inboxItem.folderPath
                    )
                case let .markAsRead(isRead):
                    guard !isRead else { return }
                    Task { // Run mark as unread operation in another thread
                        try await threadOperationsApiClient.markThreadAsUnread(
                            id: inboxItem.threadId,
                            folder: inboxItem.folderPath
                        )
                    }
                case .moveToTrash:
                    try await threadOperationsApiClient.moveThreadToTrash(id: inboxItem.threadId, labels: inboxItem.labels)
                case .moveToInbox:
                    try await threadOperationsApiClient.moveThreadToInbox(id: inboxItem.threadId)
                case .permanentlyDelete:
                    try await threadOperationsApiClient.delete(id: inboxItem.threadId)
                }

                handle(action: action)
            } catch {
                handle(action: action, error: error)
            }
        }
    }
}
