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

        perform(action: .markAsUnread)
    }

    func perform(action: MessageAction) {
        Task {
            do {
                showSpinner()
                try await messageActionsHelper.perform(action: action, with: inboxItem)
                handle(action: action)
            } catch {
                handle(action: action, error: error)
            }
        }
    }
}
