//
//  ComposeMessageAction.swift
//  FlowCrypt
//
//  Created by Roma Sosnovsky on 19/09/22
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation

enum ComposeMessageAction {
    case create(Identifier),
         update(Identifier),
         delete(Identifier),
         sent(Identifier?, Identifier)
}
