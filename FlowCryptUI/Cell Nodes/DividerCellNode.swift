//
//  DividerNode.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 31.10.2019.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import AsyncDisplayKit

public final class DividerCellNode: CellNode {
    private let line = ASDisplayNode()
    private let inset: UIEdgeInsets

    public init(
        inset: UIEdgeInsets = .zero,
        color: UIColor = .lightGray,
        height: CGFloat = 0.5
    ) {
        self.inset = inset
        super.init()
        line.style.preferredSize.height = height
        line.backgroundColor = color
        backgroundColor = color
    }

    public override func layoutSpecThatFits(_: ASSizeRange) -> ASLayoutSpec {
        ASInsetLayoutSpec(insets: inset, child: line)
    }
}
