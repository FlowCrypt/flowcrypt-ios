//
//  InboxViewController+State.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 10.10.2021
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//
    
import Foundation

extension InboxViewController {
    enum State {
        /// Just loaded scene
        case idle
        /// Fetched without any messages
        case empty
        /// Performing fetching of new messages
        case fetching
        /// Performing refreshing
        case refresh
        /// Fetched messages
        case fetched(_ pagination: MessagesListPagination)
        /// error state with description message
        case error(_ message: String)

        var canLoadMore: Bool {
            switch self {
            case let .fetched(.byNextPage(token)):
                return token != nil
            case let .fetched(.byNumber(total)):
                return (total ?? 0) > 0
            default:
                return false
            }
        }

        var token: String? {
            switch self {
            case let .fetched(.byNextPage(token)):
                return token
            default:
                return nil
            }
        }
    }
}
