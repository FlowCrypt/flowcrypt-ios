//
//  LabelCellNode.swift
//  FlowCryptUI
//
//  Created by Roma Sosnovsky on 13/10/21
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//
    
import AsyncDisplayKit

public final class LabelCellNode: CellNode {
    private let titleNode = ASTextNode2()
    private let textNode = ASTextNode2()
    private let insets: UIEdgeInsets

    public init(
        title: NSAttributedString,
        text: NSAttributedString,
        insets: UIEdgeInsets = UIEdgeInsets.deviceSpecificTextInsets(top: 8, bottom: 8)
    ) {
        self.insets = insets
        super.init()
        titleNode.attributedText = title
        textNode.attributedText = text
    }

    public override func layoutSpecThatFits(_: ASSizeRange) -> ASLayoutSpec {
        ASInsetLayoutSpec(
            insets: insets,
            child: ASStackLayoutSpec(
                direction: .vertical,
                spacing: 4,
                justifyContent: .start,
                alignItems: .start,
                children: [titleNode, textNode]
            )
        )
    }
}
