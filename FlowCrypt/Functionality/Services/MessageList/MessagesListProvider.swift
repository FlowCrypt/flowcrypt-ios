//
//  MessagesListProvider.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 17.11.2020.
//  Copyright © 2020 FlowCrypt Limited. All rights reserved.
//

import Foundation
import Promises

enum MessagesListPagination {
    case byNumber(total: Int?)
    case byNextPage(token: String?)
}

enum MessagesListProviderError {
    case provider
}

protocol MessagesListProvider {
    func fetchMessages(for folderPath: String, count: Int, using pagination: MessagesListPagination) -> Promise<MessageContext>
}
