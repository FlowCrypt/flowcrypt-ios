//
//  MessageActionsHandler.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 18.10.2021
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import UIKit
import FlowCryptUI
import FlowCryptCommon

@MainActor
protocol MessageActionsHandler: AnyObject {
    var currentFolderPath: String { get }
    var trashFolderProvider: TrashFolderProviderType { get }

    func handleTrashTap()
    func handleAttachmentTap()
    func handleInfoTap()
    func handleArchiveTap()
    func handleMoveToInboxTap()
    func handleMarkUnreadTap()

    func permanentlyDelete()
    func moveToTrash(with trashPath: String)
}

extension MessageActionsHandler where Self: UIViewController {
    private var logger: Logger {
        Logger.nested("MessageActions")
    }

    func setupNavigationBar(thread: MessageThread) {
        Task {
            do {
                let path = try await trashFolderProvider.trashFolderPath
                setupNavigationBarItems(thread: thread, trashFolderPath: path)
            } catch {
                // todo - handle?
                logger.logError("setupNavigationBar: \(error)")
            }
        }
    }

    private func setupNavigationBarItems(thread: MessageThread, trashFolderPath: String?) {
        logger.logInfo("setup navigation bar with \(trashFolderPath ?? "N/A")")
        logger.logInfo("currentFolderPath \(currentFolderPath)")

        let helpButton = NavigationBarItemsView.Input(
            image: UIImage(systemName: "questionmark.circle"),
            accessibilityId: "aid-help-button"
        ) { [weak self] in
            self?.handleInfoTap()
        }
        let archiveButton = NavigationBarItemsView.Input(
            image: UIImage(systemName: "tray.and.arrow.down"),
            accessibilityId: "aid-archive-button"
        ) { [weak self] in
            self?.handleArchiveTap()
        }
        let moveToInboxButton = NavigationBarItemsView.Input(
            image: UIImage(systemName: "tray.and.arrow.up"),
            accessibilityId: "aid-move-to-inbox-button"
        ) { [weak self] in
            self?.handleMoveToInboxTap()
        }
        let trashButton = NavigationBarItemsView.Input(
            image: UIImage(systemName: "trash"),
            accessibilityId: "aid-delete-button"
        ) { [weak self] in
            self?.handleTrashTap()
        }
        let unreadButton = NavigationBarItemsView.Input(
            image: UIImage(systemName: "envelope"),
            accessibilityId: "aid-read-button"
        ) { [weak self] in
            self?.handleMarkUnreadTap()
        }

        var items: [NavigationBarItemsView.Input]

        switch currentFolderPath.lowercased() {
        case trashFolderPath?.lowercased():
            logger.logInfo("trash - helpButton, moveToInboxButton, trashButton")
            // in case we are in trash folder ([Gmail]/Trash or Deleted for Outlook, etc)
            // we need to have only help, 'move to inbox' and trash buttons
            items = [helpButton, moveToInboxButton, trashButton]
        case "draft":
            // for Gmail inbox we also need to have archive and unread buttons
            logger.logInfo("draft - helpButton, trashButton")
            items = [helpButton, trashButton]
        default:
            // in any other folders
            items = [helpButton, trashButton, unreadButton]
            if thread.isInbox {
                logger.logInfo("inbox - helpButton, archiveButton, trashButton, unreadButton")
                items.insert(archiveButton, at: 1)
            } else if thread.shouldShowMoveToInboxButton {
                logger.logInfo("archive - helpButton, moveToInboxButton, trashButton, unreadButton")
                items.insert(moveToInboxButton, at: 1)
            } else {
                logger.logInfo("sent - helpButton, trashButton, unreadButton")
            }
        }

        navigationItem.rightBarButtonItem = NavigationBarItemsView(with: items)
    }

    func handleInfoTap() {
        showToast("Email us at human@flowcrypt.com")
    }

    func handleAttachmentTap() {
        showToast("Downloading attachments is not implemented yet")
    }

    func handleTrashTap() {
        Task {
            do {
                guard let trashPath = try await trashFolderProvider.trashFolderPath else {
                    return
                }

                deleteMessage(trashPath: trashPath)
            } catch {
                showToast(error.errorMessage)
            }
        }
    }

    private func deleteMessage(trashPath: String) {
        guard currentFolderPath.caseInsensitiveCompare(trashPath) != .orderedSame else {
            awaitUserDeleteConfirmation { [weak self] in
                self?.permanentlyDelete()
            }
            return
        }

        moveToTrash(with: trashPath)
    }

    private func awaitUserDeleteConfirmation(_ completion: @escaping () -> Void) {
        let alert = UIAlertController(
            title: "message_permanently_delete_title".localized,
            message: "message_permanently_delete".localized,
            preferredStyle: .alert
        )
        alert.addAction(
            UIAlertAction(title: "cancel".localized, style: .default)
        )
        alert.addAction(
            UIAlertAction(title: "delete".localized, style: .destructive) { _ in
                completion()
            }
        )
        present(alert, animated: true, completion: nil)
    }
}
