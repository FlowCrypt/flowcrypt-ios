//
//  CellNode.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 31.10.2019.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import AsyncDisplayKit

open class CellNode: ASCellNode {
    override public init() {
        super.init()
        automaticallyManagesSubnodes = true
        selectionStyle = .none
        backgroundColor = .backgroundColor
    }
}
