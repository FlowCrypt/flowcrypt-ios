//
//  ContactCellNode.swift
//  FlowCryptUI
//
//  Created by Anton Kharchevskyi on 22/08/2020.
//  Copyright © 2020 FlowCrypt Limited. All rights reserved.
//

import AsyncDisplayKit

public final class ContactCellNode: CellNode {
    private let textNode = ASTextNode2()
    private let insets: UIEdgeInsets

    public init(title: NSAttributedString, insets: UIEdgeInsets) {
        self.insets = insets
        super.init()
        textNode.attributedText = title
    }

    public override func layoutSpecThatFits(_: ASSizeRange) -> ASLayoutSpec {
        ASInsetLayoutSpec(
            insets: insets,
            child: textNode
        )
    }
}
