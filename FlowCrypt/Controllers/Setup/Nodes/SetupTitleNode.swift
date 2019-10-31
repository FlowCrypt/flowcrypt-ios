//
//  SetupTitleNode.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 29.10.2019.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import AsyncDisplayKit

final class SetupTitleNode: CellNode {
    private let textNode = ASTextNode()
    private let insets: UIEdgeInsets

    init(_ title: NSAttributedString, insets: UIEdgeInsets) {
        self.insets = insets
        super.init()
        self.textNode.attributedText = title
    }

    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        ASInsetLayoutSpec(
            insets: insets,
            child: ASCenterLayoutSpec(centeringOptions: .XY, sizingOptions: .minimumXY, child: textNode)
        )
    }
}
