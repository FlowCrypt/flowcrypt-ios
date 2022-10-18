//
//  KeyTextCellNode.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 12/13/19.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import AsyncDisplayKit

public final class KeyTextCellNode: CellNode {

    private let insets: UIEdgeInsets
    private let textNode = ASTextNode2()

    public init(
        title: NSAttributedString,
        insets: UIEdgeInsets
    ) {
        self.insets = insets
        super.init()
        textNode.attributedText = title
    }

    override public func layoutSpecThatFits(_: ASSizeRange) -> ASLayoutSpec {
        ASInsetLayoutSpec(
            insets: insets,
            child: textNode
        )
    }
}
