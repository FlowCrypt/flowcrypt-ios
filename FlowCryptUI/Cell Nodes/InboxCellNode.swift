//
//  InboxCellNode.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 01.10.2019.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import AsyncDisplayKit

public final class InboxCellNode: CellNode {
    public struct Input {
        public let emailText: NSAttributedString
        public let dateText: NSAttributedString
        public let messageText: NSAttributedString?

        public init(
            emailText: NSAttributedString,
            dateText: NSAttributedString,
            messageText: NSAttributedString?
        ) {
            self.emailText = emailText
            self.dateText = dateText
            self.messageText = messageText
        }
    }

    private let emailNode = ASTextNode2()
    private let dateNode = ASTextNode2()
    private lazy var messageNode: ASTextNode2? = ASTextNode2()
    private let separatorNode = ASDisplayNode()

    public init(input: Input) {
        super.init()
        emailNode.attributedText = input.emailText
        dateNode.attributedText = input.dateText

        if let message = input.messageText {
            messageNode?.attributedText = message
            messageNode?.maximumNumberOfLines = 1
            messageNode?.truncationMode = .byTruncatingTail
        }

        emailNode.maximumNumberOfLines = 1
        dateNode.maximumNumberOfLines = 1
        emailNode.truncationMode = .byTruncatingTail
        separatorNode.backgroundColor = .lightGray
    }

    public override func layoutSpecThatFits(_: ASSizeRange) -> ASLayoutSpec {
        let nameLocationStack = ASStackLayoutSpec.vertical()
        nameLocationStack.spacing = 6
        nameLocationStack.style.flexShrink = 1.0
        nameLocationStack.style.flexGrow = 1.0
        separatorNode.style.flexGrow = 1.0
        separatorNode.style.preferredSize.height = 1.0


        if let messageNode = messageNode {
            nameLocationStack.children = [emailNode, messageNode]
        } else {
            nameLocationStack.children = [emailNode]
        }

        let headerStackSpec = ASStackLayoutSpec(
            direction: .horizontal,
            spacing: 8,
            justifyContent: .start,
            alignItems: .baselineFirst,
            children: [nameLocationStack, dateNode]
        )

        let finalSpec = ASStackLayoutSpec.vertical()
        finalSpec.children = [headerStackSpec, separatorNode]
        finalSpec.spacing = 8
        return ASInsetLayoutSpec(
            insets: UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16),
            child: finalSpec
        )
    }
}
