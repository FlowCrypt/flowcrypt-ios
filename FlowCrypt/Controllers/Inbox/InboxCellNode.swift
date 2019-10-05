//
//  InboxCellNode.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 01.10.2019.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import AsyncDisplayKit
import Foundation

final class InboxCellNode: ASCellNode {
    private let emailNode = ASTextNode()
    private let dateNode = ASTextNode()
    private let messageNode = ASTextNode()

    init(message: InboxCellNodeInput) {
        super.init()
        addSubnode(emailNode)
        addSubnode(dateNode)
        addSubnode(messageNode)

        emailNode.attributedText = message.emailText
        dateNode.attributedText = message.dateText
        messageNode.attributedText = message.messageText

        emailNode.maximumNumberOfLines = 1
        dateNode.maximumNumberOfLines = 1
        messageNode.maximumNumberOfLines = 1

        emailNode.truncationMode = .byTruncatingTail
        messageNode.truncationMode = .byTruncatingTail
    }

    override func layoutSpecThatFits(_: ASSizeRange) -> ASLayoutSpec {
        let nameLocationStack = ASStackLayoutSpec.vertical()
        nameLocationStack.spacing = 6
        nameLocationStack.style.flexShrink = 1.0
        nameLocationStack.style.flexGrow = 1.0

        nameLocationStack.children = [emailNode, messageNode]

        let headerStackSpec = ASStackLayoutSpec(
            direction: .horizontal,
            spacing: 8,
            justifyContent: .start,
            alignItems: .baselineFirst,
            children: [nameLocationStack, dateNode]
        )

        return ASInsetLayoutSpec(
            insets: UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16),
            child: headerStackSpec
        )
    }
}
