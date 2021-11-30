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
    func handleMarkUnreadTap()

    func permanentlyDelete()
    func moveToTrash(with trashPath: String)
}

extension MessageActionsHandler where Self: UIViewController {
    private var logger: Logger {
        Logger.nested("MessageActions")
    }

    func setupNavigationBar(user: User) {
        Task {
            do {
                let path = try await trashFolderProvider.getTrashFolderPath(for: user)
                setupNavigationBarItems(with: path)
            } catch {
                // todo - handle?
                logger.logError("setupNavigationBar: \(error)")
            }
        }
    }

    private func setupNavigationBarItems(with trashFolderPath: String?) {
        logger.logInfo("setup navigation bar with \(trashFolderPath ?? "N/A")")
        logger.logInfo("currentFolderPath \(currentFolderPath)")

        let helpButton = NavigationBarItemsView.Input(image: UIImage(named: "help_icn")) { [weak self] in
            self?.handleInfoTap()
        }
        let archiveButton = NavigationBarItemsView.Input(image: UIImage(named: "archive")) { [weak self] in
            self?.handleArchiveTap()
        }
        let trashButton = NavigationBarItemsView.Input(image: UIImage(named: "trash")) { [weak self] in
            self?.handleTrashTap()
        }
        let unreadButton = NavigationBarItemsView.Input(image: UIImage(named: "mail")) { [weak self] in
            self?.handleMarkUnreadTap()
        }

        let items: [NavigationBarItemsView.Input]

        switch currentFolderPath.lowercased() {
        case trashFolderPath?.lowercased():
            logger.logInfo("trash - helpButton, trashButton")
            // in case we are in trash folder ([Gmail]/Trash or Deleted for Outlook, etc)
            // we need to have only help and trash buttons
            items = [helpButton, trashButton]

        // TODO: - Ticket - Check if this should be fixed
        case "inbox":
            // for Gmail inbox we also need to have archive and unread buttons
            logger.logInfo("inbox - helpButton, archiveButton, trashButton, unreadButton")
            items = [helpButton, archiveButton, trashButton, unreadButton]
        default:
            // in any other folders
            logger.logInfo("default - helpButton, trashButton, unreadButton")
            items = [helpButton, trashButton, unreadButton]
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
                let trashPath = try await trashFolderProvider.getTrashFolderPath(for: <#User#>)
                guard let trashPath = trashPath else {
                    return
                }
                if self.currentFolderPath.caseInsensitiveCompare(trashPath) == .orderedSame {
                    self.awaitUserConfirmation { [weak self] in
                        self?.permanentlyDelete()
                    }
                } else {
                    self.moveToTrash(with: trashPath)
                }
            } catch {
                showToast(error.localizedDescription)
            }
        }
    }

    func awaitUserConfirmation(_ completion: @escaping () -> Void) {
        let alert = UIAlertController(
            title: "Are you sure?",
            message: "You're about to permanently delete a message",
            preferredStyle: .alert
        )
        alert.addAction(
            UIAlertAction(title: "Cancel", style: .default)
        )
        alert.addAction(
            UIAlertAction(title: "OK", style: .default) { _ in
                completion()
            }
        )
        present(alert, animated: true, completion: nil)
    }
}
