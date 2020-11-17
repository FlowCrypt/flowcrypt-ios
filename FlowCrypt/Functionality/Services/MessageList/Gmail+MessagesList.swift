//
//  Gmail_MessagesList.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 17.11.2020.
//  Copyright © 2020 FlowCrypt Limited. All rights reserved.
//

import Promises
import GTMSessionFetcher
import GoogleAPIClientForREST

extension GmailService: MessagesListProvider {
    func fetchMessages(for folder: String, count: Int, using pagination: MessagesListPagination) -> Promise<MessageContext> {
        guard case let .byNextPage(token) = pagination else {
            fatalError("Pagination \(pagination) is not supported for this provider")
        }
        return Promise { (resolve, reject) in
            let query = GTLRGmailQuery_UsersMessagesList.query(withUserId: .me)
            query.includeSpamTrash = false
//            query.labelIds = [""]
            query.maxResults = UInt(count)




            self.gmailService.executeQuery(query) { (_, data, error) in
                if let error = error {
                    reject(FoldersProviderError.providerError(error))
                }

                guard let messageList = data as? GTLRGmail_ListMessagesResponse else {
                    return reject(AppErr.cast("GTLRGmail_ListMessagesResponse"))
                }

                let messages: [GTLRGmail_Message] = messageList.messages ?? []
                let nextPageToken: String? = messageList.nextPageToken



                resolve(MessageContext(messages: [], totalMessages: 0))
            }
        }
    }
}
