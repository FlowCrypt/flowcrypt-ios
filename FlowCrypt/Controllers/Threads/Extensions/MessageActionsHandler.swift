//
//  MessageActionsHandler.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 18.10.2021
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import FlowCryptCommon
import FlowCryptUI
import UIKit

@MainActor
protocol MessageActionsHandler: AnyObject {
    var currentFolderPath: String { get }
    var trashFolderPath: String? { get async throws }

    func handleTrashTap()
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

    func setupNavigationBar(inboxItem: InboxItem) {
        Task {
            do {
                let path = try await trashFolderPath
                setupNavigationBarItems(inboxItem: inboxItem, trashFolderPath: path)
            } catch {
                // todo - handle?
                logger.logError("setupNavigationBar: \(error)")
            }
        }
    }

    private func setupNavigationBarItems(inboxItem: InboxItem, trashFolderPath: String?) {
        logger.logInfo("""
        setup navigation bar with \(trashFolderPath ?? "N/A")")
        currentFolderPath \(currentFolderPath)
        """)

        let helpButton = NavigationBarItemsView.Input(
            image: UIImage(systemName: "questionmark.circle"),
            accessibilityId: "aid-help-button"
        ) { [weak self] in
            self?.handleInfoTap()
        }

        var actions: [MessageAction]
        switch currentFolderPath.lowercased() {
        case trashFolderPath?.lowercased():
            actions = [.moveToInbox, .moveToTrash]
        case "draft":
            actions = [.moveToTrash]
        default:
            actions = [.moveToTrash, .markAsUnread]
            actions.insert(inboxItem.isInbox ? .archive : .moveToInbox, at: 0)
        }

        let items = [helpButton] + actions.map { createNavigationBarButton(action: $0) }
        navigationItem.rightBarButtonItem = NavigationBarItemsView(with: items)
    }

    private func createNavigationBarButton(action: MessageAction) -> NavigationBarItemsView.Input {
        .init(
            image: action.image,
            accessibilityId: action.accessibilityIdentifier
        ) { [weak self] in
            switch action {
            case .moveToTrash, .permanentlyDelete:
                self?.handleTrashTap()
            case .moveToInbox:
                self?.handleMoveToInboxTap()
            case .archive:
                self?.handleArchiveTap()
            case .markAsUnread:
                self?.handleMarkUnreadTap()
            case .markAsRead:
                break
            }
        }
    }

    func handleInfoTap() {
        showToast("Email us at human@flowcrypt.com")
    }

    func handleTrashTap() {
        Task {
            do {
                guard let trashPath = try await trashFolderPath else {
                    return
                }

                if currentFolderPath.caseInsensitiveCompare(trashPath) != .orderedSame {
                    moveToTrash(with: trashPath)
                } else {
                    permanentlyDelete()
                }
            } catch {
                showToast(error.errorMessage)
            }
        }
    }
}
