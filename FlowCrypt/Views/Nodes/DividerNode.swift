//
//  DividerNode.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 31.10.2019.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import AsyncDisplayKit

final class DividerNode: CellNode {
    private let line = ASDisplayNode()
    private let inset: UIEdgeInsets

    init(inset: UIEdgeInsets, color: UIColor, height: CGFloat) {
        self.inset = inset
        super.init()
        line.style.preferredSize.height = height
        line.backgroundColor = color
    }

    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        ASInsetLayoutSpec(insets: inset, child: line)
    }
}
