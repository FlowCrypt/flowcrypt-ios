//
//  ComposeMessageAction.swift
//  FlowCrypt
//
//  Created by Roma Sosnovsky on 19/09/22
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation

enum ComposeMessageAction {
    case update(MessageIdentifier),
         delete(MessageIdentifier),
         sent(MessageIdentifier)
}
