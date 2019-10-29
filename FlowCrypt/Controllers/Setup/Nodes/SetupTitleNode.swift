//
//  SetupTitleNode.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 29.10.2019.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import AsyncDisplayKit

final class SetupTitleNode: ASCellNode {
    private let textNode = ASTextNode()

    init(_ title: NSAttributedString = SetupStyle.title) {
        super.init()
        automaticallyManagesSubnodes = true
        selectionStyle = .none
        textNode.attributedText = title
    }

    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        ASInsetLayoutSpec(
            insets: UIEdgeInsets(top: 502, left: 16, bottom: 16, right: 16),
            child: ASCenterLayoutSpec(centeringOptions: .XY, sizingOptions: .minimumXY, child: textNode)
        )
    }
}
