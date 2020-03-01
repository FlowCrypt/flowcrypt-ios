//
//  SettingsCellNode.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 12/9/19.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import AsyncDisplayKit
import FlowCryptUI

// TODO: ANTON - Move to FlowCryptUI
final class SettingsCellNode: CellNode {
    private let textNode = ASTextNode()
    private let insets: UIEdgeInsets

    init(title: NSAttributedString, insets: UIEdgeInsets) {
        self.insets = insets
        super.init()
        textNode.attributedText = title
    }

    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        ASInsetLayoutSpec(
            insets: insets,
            child: textNode
        )
    }
}
