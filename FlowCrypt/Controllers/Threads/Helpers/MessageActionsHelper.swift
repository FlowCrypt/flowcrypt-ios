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
        self.trashFolderProvider = try await TrashFolderProvider(
            user: appContext.user,
            foldersManager: appContext.getFoldersManager()
        )
        self.threadOperationsApiClient = try await appContext.getRequiredMailProvider().threadOperationsApiClient
    }

    @MainActor
    func perform( // swiftlint:disable:this function_body_length
        action: MessageAction,
        with inboxItem: InboxItem,
        viewController: UIViewController,
        showSpinner: Bool = true
    ) async throws {
        if showSpinner {
            viewController.showSpinner()
        }
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
            Task { // Run mark as read operation in another thread
                try await threadOperationsApiClient.markThreadAsRead(
                    id: inboxItem.threadId,
                    folder: inboxItem.folderPath
                )
            }
        case .moveToTrash:
            try await threadOperationsApiClient.moveThreadToTrash(
                id: inboxItem.threadId,
                labels: inboxItem.labels
            )
        case .moveToInbox:
            try await threadOperationsApiClient.moveThreadToInbox(id: inboxItem.threadId)
        case .permanentlyDelete:
            try await withCheckedThrowingContinuation { continuation in
                viewController.showPermanentDeleteThreadAlert(
                    threadCount: 1,
                    onAction: { _ in
                        Task {
                            if showSpinner {
                                viewController.showSpinner()
                            }
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
