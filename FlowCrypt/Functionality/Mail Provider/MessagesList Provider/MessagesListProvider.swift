//
//  MessagesListProvider.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 17.11.2020.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation

struct FetchMessageContext {
    /// Specify specific folder, or in all folders
    let folderPath: String?
    /// Specify number of messages to fetch, or all
    let count: Int?
    /// Specify search query. https://support.google.com/mail/answer/7190?hl=en
    let searchQuery: String?
    /// Pagination
    let pagination: MessagesListPagination?

    // Folder path might be nil in case when user wants to search for all folders
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

protocol MessagesListProvider {
    func fetchMessage(id: Identifier, folder: String) async throws -> Message
    func fetchMessages(using context: FetchMessageContext) async throws -> MessageContext
}
