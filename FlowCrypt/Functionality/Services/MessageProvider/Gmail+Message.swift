//
//  Gmail+Message.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 29.11.2020.
//  Copyright © 2020 FlowCrypt Limited. All rights reserved.
//

import Promises
import GTMSessionFetcher
import GoogleAPIClientForREST

extension GmailService: MessageProvider {
    func fetchMsg(message: Message, folder: String) -> Promise<Data> {
        return Promise { (resolve, reject) in
//            GTLRGmailQuery_mes
            return reject(AppErr.nilSelf)
        }

//        let query = GTL
//        query.labelIds = [folderPath]
//        query.maxResults = UInt(count)
//        query.pageToken = token
//
//        return Promise { (resolve, reject) in
//            self.gmailService.executeQuery(query) { (_, data, error) in
//                if let error = error {
//                    reject(AppErr.providerError(error))
//                }
//
//                guard let messageList = data as? GTLRGmail_ListMessagesResponse else {
//                    return reject(AppErr.cast("GTLRGmail_ListMessagesResponse"))
//                }
//
//                resolve(messageList)
//            }
//        }
    }
}
