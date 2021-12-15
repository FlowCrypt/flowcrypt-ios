//
//  TextWithPaddingNode.swift
//  FlowCryptUI
//
//  Created by Roma Sosnovsky on 15/12/21
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import AsyncDisplayKit

public final class TextWithPaddingNode: ASDisplayNode {
    private let insets: UIEdgeInsets
    private let textNode = ASTextNode2()

    public init(
        text: NSAttributedString?,
        insets: UIEdgeInsets,
        backgroundColor: UIColor? = nil,
        cornerRadius: CGFloat = 0
    ) {
        self.insets = insets

        super.init()

        automaticallyManagesSubnodes = true
        textNode.attributedText = text

        self.backgroundColor = backgroundColor
        self.cornerRadius = cornerRadius
    }

    public override func layoutSpecThatFits(_: ASSizeRange) -> ASLayoutSpec {
        ASInsetLayoutSpec(
            insets: insets,
            child: textNode
        )
    }
}
