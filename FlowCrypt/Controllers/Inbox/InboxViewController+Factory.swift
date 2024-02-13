//
//  InboxViewController+Factory.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 10.10.2021
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import UIKit

enum InboxViewControllerFactory {
    @MainActor
    static func make(appContext: AppContextWithUser, viewModel: InboxViewModel) async throws -> InboxViewController {
        let apiClient: InboxDataApiClient
        let numberOfInboxItemsToLoad: Int

        switch appContext.authType {
        case .oAuthGmail:
            // Inject threads api client - Gmail API
            apiClient = try InboxMessageThreadsProvider(
                apiClient: appContext.getRequiredMailProvider().messagesThreadApiClient
            )
            numberOfInboxItemsToLoad = 20 // else timeouts happen
        case .password:
            // Inject message list provider - IMAP
            apiClient = try InboxMessageListProvider(
                apiClient: appContext.getRequiredMailProvider().messagesListApiClient
            )
            numberOfInboxItemsToLoad = 50 // safe to load 50, single call on IMAP
        }

        return try await InboxViewController(
            appContext: appContext,
            viewModel: viewModel,
            numberOfInboxItemsToLoad: numberOfInboxItemsToLoad,
            apiClient: apiClient
        )
    }
}
