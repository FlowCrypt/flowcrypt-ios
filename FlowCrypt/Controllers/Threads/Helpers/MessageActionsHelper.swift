//
//  MessageActionsHelper.swift
//  FlowCrypt
//
//  Created by Roma Sosnovsky on 19.12.2022
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import UIKit

struct MessageActionsHelper {
    private let trashFolderProvider: TrashFolderProviderType
    private let threadOperationsApiClient: MessagesThreadOperationsApiClient

    var trashFolderPath: String? {
        get async throws {
            try await trashFolderProvider.trashFolderPath
        }
    }

    init(appContext: AppContextWithUser) async throws {
        self.trashFolderProvider = await TrashFolderProvider(
            user: appContext.user,
            foldersManager: try appContext.getFoldersManager()
        )
        self.threadOperationsApiClient = try await appContext.getRequiredMailProvider().threadOperationsApiClient
    }

    @MainActor
    func perform(action: MessageAction, with inboxItem: InboxItem, viewController: UIViewController) async throws {
        viewController.showSpinner()
        switch action {
        case .archive:
            try await threadOperationsApiClient.archive(
                messagesIds: inboxItem.messages.map(\.identifier),
                in: inboxItem.folderPath
            )
        case .markAsUnread:
            Task { // Run mark as unread operation in another thread
                try await threadOperationsApiClient.markThreadAsUnread(
                    id: inboxItem.threadId,
                    folder: inboxItem.folderPath
                )
            }
        case .markAsRead:
            break
        case .moveToTrash:
            try await threadOperationsApiClient.moveThreadToTrash(
                id: inboxItem.threadId,
                labels: inboxItem.labels
            )
        case .moveToInbox:
            try await threadOperationsApiClient.moveThreadToInbox(id: inboxItem.threadId)
        case .permanentlyDelete:
            try await withCheckedThrowingContinuation { continuation in
                viewController.showAlertWithAction(
                    title: "message_permanently_delete_title".localized,
                    message: "message_permanently_delete".localized,
                    actionButtonTitle: "delete".localized,
                    actionAccessibilityIdentifier: "aid-confirm-button",
                    actionStyle: .destructive,
                    onAction: { _ in
                        Task {
                            do {
                                try await self.threadOperationsApiClient.delete(id: inboxItem.threadId)
                                continuation.resume()
                            } catch {
                                continuation.resume(throwing: error)
                            }
                        }
                    },
                    onCancel: { _ in
                        continuation.resume(throwing: AppErr.silentAbort)
                    }
                )
            }
        }
    }
}
