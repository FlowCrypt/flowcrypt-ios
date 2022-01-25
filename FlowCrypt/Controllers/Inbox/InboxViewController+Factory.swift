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
    static func make(appContext: AppContext, user: User, viewModel: InboxViewModel) -> InboxViewController {
        guard
            let currentAuthType = appContext.dataService.currentAuthType
        else {
            fatalError("Internal inconsistency")
        }

        switch currentAuthType {
        case .oAuthGmail:
            // Inject threads provider - Gmail API
            guard let threadsProvider = appContext.getRequiredMailProvider().messagesThreadProvider else {
                fatalError("Internal inconsistency")
            }

            return InboxViewController(
                appContext: appContext,
                viewModel: viewModel,
                user: user,
                numberOfInboxItemsToLoad: 20, // else timeouts happen
                provider: InboxMessageThreadsProvider(provider: threadsProvider)
            )
        case .password:
            // Inject message list provider - IMAP
            let provider = InboxMessageListProvider(provider: appContext.getRequiredMailProvider().messageListProvider)

            return InboxViewController(
                appContext: appContext,
                viewModel: viewModel,
                user: user,
                numberOfInboxItemsToLoad: 50, // safe to load 50, single call on IMAP
                provider: provider
            )
        }
    }
}
