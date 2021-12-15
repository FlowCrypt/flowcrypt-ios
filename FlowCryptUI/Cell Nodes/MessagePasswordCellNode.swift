//
//  MessagePasswordCellNode.swift
//  FlowCryptUI
//
//  Created by Roma Sosnovsky on 15/12/21
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import AsyncDisplayKit
import UIKit

public final class MessagePasswordCellNode: CellNode {
    private let textNode: TextWithPaddingNode

    public init(_ text: NSAttributedString?) {
        textNode = TextWithPaddingNode(
            text: text,
            insets: UIEdgeInsets(top: 4, left: 6, bottom: 4, right: 6),
            backgroundColor: .main,
            cornerRadius: 6
        )
        super.init()

        automaticallyManagesSubnodes = true
    }

    public override func layoutSpecThatFits(_: ASSizeRange) -> ASLayoutSpec {
        textNode.style.flexGrow = 1.0

        return ASInsetLayoutSpec(
            insets: UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8),
            child: textNode
        )
    }
}
