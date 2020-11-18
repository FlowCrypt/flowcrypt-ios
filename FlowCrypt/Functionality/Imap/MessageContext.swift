//
//  MessageContext.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 19/12/2019.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import Foundation

struct MessageContext {
    let messages: [MCOIMAPMessage]
    let pagination: MessagesListPagination
}
