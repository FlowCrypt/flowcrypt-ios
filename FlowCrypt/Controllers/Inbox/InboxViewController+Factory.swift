//
//  InboxViewController+Factory.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 10.10.2021
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation
import UIKit

class InboxViewControllerFactory {
    @MainActor
    static func make(userContext: UserContext, viewModel: InboxViewModel) -> InboxViewController {
        switch userContext.authType {
        case .oAuthGmail:
            // Inject threads provider - Gmail API
            guard let threadsProvider = userContext.getRequiredMailProvider().messagesThreadProvider else {
                fatalError("Internal inconsistency")
            }

            return InboxViewController(
                userContext: userContext,
                viewModel: viewModel,
                numberOfInboxItemsToLoad: 20, // else timeouts happen
                provider: InboxMessageThreadsProvider(provider: threadsProvider)
            )
        case .password:
            // Inject message list provider - IMAP
            let provider = InboxMessageListProvider(provider: userContext.getRequiredMailProvider().messageListProvider)

            return InboxViewController(
                userContext: userContext,
                viewModel: viewModel,
                numberOfInboxItemsToLoad: 50, // safe to load 50, single call on IMAP
                provider: provider
            )
        }
    }
}
