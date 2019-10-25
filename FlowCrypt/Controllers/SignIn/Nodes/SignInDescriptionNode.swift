//
//  SignInDescriptionNode.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 23.10.2019.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import AsyncDisplayKit

final class SignInDescriptionNode: ASCellNode {
    private let textNode = ASTextNode()

    init(_ title: NSAttributedString?) {
        super.init()
        textNode.attributedText = title
        textNode.accessibilityLabel = "description"
        automaticallyManagesSubnodes = true
        selectionStyle = .none
    }

    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        return ASInsetLayoutSpec(
            insets: UIEdgeInsets(top: 30, left: 16, bottom: 55, right: 16),
            child: ASCenterLayoutSpec(
                centeringOptions: .XY,
                sizingOptions: .minimumXY,
                child: textNode
            )
        )
    }
}
