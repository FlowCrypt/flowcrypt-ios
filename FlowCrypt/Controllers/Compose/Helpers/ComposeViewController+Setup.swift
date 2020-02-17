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

        var recipientReplyTitle: String? {
            isReply ? replyToRecipient?.mailbox : nil
        }

        var subjectReplyTitle: String? {
            isReply ? "Re: \(replyToSubject ?? "(no subject)")" : nil
        }

        var successfullySentToast: String {
            isReply ? "compose_reply_successfull".localized : "compose_sent".localized
        }
    }

    struct Context {
        var message: String?
        var recipient: String?
        var subject: String?
    }
}
