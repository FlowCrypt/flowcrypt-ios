//
//  ComposeViewController+Setup.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 05.11.2019.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import Foundation

extension ComposeViewController {
    enum Parts: Int, CaseIterable {
           case recipient, recipientDivider, subject, subjectDivider, text
       }
    
    struct Input {
        static let empty = Input(isReply: false, replyToRecipient: nil, replyToSubject: nil, replyToMime: nil)

        let isReply: Bool
        let replyToRecipient: MCOAddress?
        let replyToSubject: String?
        let replyToMime: Data?
    }

    struct Context {
        var message: String?
        var resipient: String?
        var subject: String?
    }
}
