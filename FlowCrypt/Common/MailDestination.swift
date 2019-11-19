//
//  MailDestination.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 06.11.2019.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import Foundation

enum MailDestination {
    enum Gmail {
        case trash, inbox

        var path: String {
            switch self {
            case .trash: return "[Gmail]/Trash"
            case .inbox: return "Inbox"
            }
        }
    }
}
