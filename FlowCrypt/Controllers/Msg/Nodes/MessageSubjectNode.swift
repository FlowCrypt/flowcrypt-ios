//
//  MessageSubjectNode.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 06.11.2019.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import AsyncDisplayKit

final class MessageSubjectNode: CellNode {
    private let textNode = ASTextNode()
    private let timeNode = ASTextNode()

    init(_ text: NSAttributedString?, time: NSAttributedString?) {
        super.init()
        textNode.attributedText = text
        timeNode.attributedText = time
    }

    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        textNode.style.flexGrow = 1.0
        return ASInsetLayoutSpec(
            insets: UIEdgeInsets(top: 2, left: 8, bottom: 0, right: 8),
            child: ASStackLayoutSpec(
                direction: .horizontal,
                spacing: 8,
                justifyContent: .start,
                alignItems: .center,
                children: [textNode, timeNode]
            )
        )
    }
}
