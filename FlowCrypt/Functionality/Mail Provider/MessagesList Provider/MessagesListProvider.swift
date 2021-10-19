//
//  MessagesListProvider.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 17.11.2020.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation
import Promises

struct FetchMessageContext {
    /// Specify specific folder, or in all folders
    let folderPath: String?
    /// Specify number of messages to fetch, or all
    let count: Int?
    /// Specify search query. https://support.google.com/mail/answer/7190?hl=en
    let searchQuery: String?
    /// Pagination
    let pagination: MessagesListPagination?

    init(folderPath: String?, count: Int?, searchQuery: String? = nil, pagination: MessagesListPagination?) {
        self.folderPath = folderPath
        self.count = count
        self.searchQuery = searchQuery
        self.pagination = pagination
    }
}

enum MessagesListPagination {
    case byNumber(total: Int?)
    case byNextPage(token: String?)
}

enum MessagesListProviderError {
    case provider
}

protocol MessagesListProvider {
    func fetchMessages(using context: FetchMessageContext) -> Promise<MessageContext>
}
