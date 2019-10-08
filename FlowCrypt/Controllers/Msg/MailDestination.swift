//
// Created by Anton Kharchevskyi on 9/16/19.
// Copyright (c) 2019 FlowCrypt Limited. All rights reserved.
//

import Foundation

enum MailDestination {
    enum Gmail {
        case trash, inbox

        var path: String {
            switch self {
            case .trash: return "[Gmail]/Trash"
            case .inbox: return "[Gmail]/Inbox"
            }
        }
    }
}
