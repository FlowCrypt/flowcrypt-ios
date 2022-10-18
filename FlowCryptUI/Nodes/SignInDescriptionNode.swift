//
//  SignInDescriptionNode.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 23.10.2019.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import AsyncDisplayKit

public final class SignInDescriptionNode: CellNode {
    private let textNode = ASTextNode2()

    public init(_ title: NSAttributedString?) {
        super.init()
        textNode.attributedText = title
        textNode.accessibilityLabel = "description"
        automaticallyManagesSubnodes = true
        selectionStyle = .none
    }

    override public func layoutSpecThatFits(_: ASSizeRange) -> ASLayoutSpec {
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
