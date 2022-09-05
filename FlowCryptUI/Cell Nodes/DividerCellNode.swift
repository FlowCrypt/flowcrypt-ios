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
        backgroundColor = .clear
    }

    override public func layoutSpecThatFits(_ range: ASSizeRange) -> ASLayoutSpec {
        let expectedWidth = range.max.width - inset.width
        line.style.preferredSize.width = expectedWidth > 0 ? expectedWidth : range.max.width
        return ASInsetLayoutSpec(insets: inset, child: line)
    }
}
