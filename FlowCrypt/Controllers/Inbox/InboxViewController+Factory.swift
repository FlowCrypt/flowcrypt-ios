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
    // TODO: - ANTON - remove
    static var counter = 0

    static func make(with viewModel: InboxViewModel) -> InboxViewController {
        guard let currentAuthType = DataService.shared.currentAuthType else {
            fatalError("Internal inconsistency")
        }

        switch currentAuthType {
        case .oAuthGmail:
            // Inject threads provide
            guard let threadsProvider = MailProvider.shared.messagesThreadProvider else {
                fatalError("Internal inconsistency")
            }

            if counter % 2 == 0 {
                counter += 1
                return InboxViewController(
                    viewModel,
                    numberOfMessagesToLoad: 20,
                    provider: InboxMessageThreadsProvider(provider: threadsProvider)
                )
            } else {
                counter += 1
                return InboxViewController(
                    viewModel,
                    numberOfMessagesToLoad: 20,
                    provider: InboxMessageListProvider()
                )
            }
        case .password:
            // Inject message list provider
            let provider = InboxMessageListProvider()

            return InboxViewController(
                viewModel,
                numberOfMessagesToLoad: 50,
                provider: provider
            )
        }
    }
}
