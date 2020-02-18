//
//  DividerNode.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 31.10.2019.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import AsyncDisplayKit

#warning("Should use Cell node instead of ASCellNode")
final public class DividerNode: CellNode {
    private let line = ASDisplayNode()
    private let inset: UIEdgeInsets

    public init(
        inset: UIEdgeInsets = .zero,
        color: UIColor = .lightGray,
        height: CGFloat = 1
    ) {
        self.inset = inset
        super.init()
        line.style.preferredSize.height = height
        line.backgroundColor = color
        backgroundColor = color
    }

    public override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        ASInsetLayoutSpec(insets: inset, child: line)
    }
}
