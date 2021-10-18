//
//  MessageActionsHandler.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 18.10.2021
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import UIKit
import FlowCryptUI

protocol MessageActionsHandler: AnyObject {
    var currentFolderPath: String { get }
    var trashFolderProvider: TrashFolderProviderType { get }

    func handleTrashTap()
    func handleAttachmentTap()
    func handleInfoTap()
    func handleArchiveTap()
    func handleMarkUnreadTap()
}

extension MessageActionsHandler where Self: UIViewController {
    func setupNavigationBar() {
        trashFolderProvider.getTrashFolderPath()
            .then(on: .main) { [weak self] path in
                self?.setupNavigationBarItems(with: path)
            }
    }

    private func setupNavigationBarItems(with trashFolderPath: String?) {
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
            // in case we are in trash folder ([Gmail]/Trash or Deleted for Outlook, etc)
            // we need to have only help and trash buttons
            items = [helpButton, trashButton]

        // TODO: - Ticket - Check if this should be fixed
        case "inbox":
            // for Gmail inbox we also need to have archive and unread buttons
            items = [helpButton, archiveButton, trashButton, unreadButton]
        default:
            // in any other folders
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
}
