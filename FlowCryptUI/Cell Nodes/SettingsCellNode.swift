//
//  SettingsCellNode.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 12/9/19.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import AsyncDisplayKit

public final class SettingsCellNode: CellNode {
    private let textNode = ASTextNode2()
    private let insets: UIEdgeInsets

    public init(title: NSAttributedString, insets: UIEdgeInsets) {
        self.insets = insets
        super.init()
        textNode.attributedText = title
    }

    public override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        ASInsetLayoutSpec(
            insets: insets,
            child: textNode
        )
    }
}
