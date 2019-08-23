//
//  MailDestinations.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 8/22/19.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import Foundation

enum MailDestination {
    enum Gmail {
        case trash

        var path: String {
            switch self {
            case .trash: return "[Gmail]/Trash"
            }
        }
    }
}
