//
//  InboxViewController+Factory.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 10.10.2021
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import UIKit

class InboxViewControllerFactory {
    @MainActor
    static func make(appContext: AppContextWithUser, viewModel: InboxViewModel) throws -> InboxViewController {
        switch appContext.authType {
        case .oAuthGmail:
            // Inject threads provider - Gmail API
            let threadsProvider = try appContext.getRequiredMailProvider().messagesThreadProvider

            return try InboxViewController(
                appContext: appContext,
                viewModel: viewModel,
                numberOfInboxItemsToLoad: 20, // else timeouts happen
                provider: InboxMessageThreadsProvider(provider: threadsProvider)
            )
        case .password:
            // Inject message list provider - IMAP
            let provider = InboxMessageListProvider(provider: try appContext.getRequiredMailProvider().messageListProvider)

            return try InboxViewController(
                appContext: appContext,
                viewModel: viewModel,
                numberOfInboxItemsToLoad: 50, // safe to load 50, single call on IMAP
                provider: provider
            )
        }
    }
}
