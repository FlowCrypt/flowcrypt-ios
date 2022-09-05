//
//  ButtonWithPaddingNode.swift
//  FlowCryptUI
//
//  Created by Roma Sosnovsky on 15/12/21
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import AsyncDisplayKit

public final class ButtonWithPaddingNode: ASDisplayNode {
    private let insets: UIEdgeInsets
    private let buttonNode = ASTextNode2()

    public init(
        text: NSAttributedString?,
        insets: UIEdgeInsets,
        backgroundColor: UIColor? = nil,
        cornerRadius: CGFloat = 0,
        action: (() -> Void)?
    ) {
        self.insets = insets

        super.init()

        automaticallyManagesSubnodes = true
        buttonNode.attributedText = text

        self.backgroundColor = backgroundColor
        self.cornerRadius = cornerRadius
    }

    override public func layoutSpecThatFits(_: ASSizeRange) -> ASLayoutSpec {
        ASInsetLayoutSpec(
            insets: insets,
            child: buttonNode
        )
    }
}
