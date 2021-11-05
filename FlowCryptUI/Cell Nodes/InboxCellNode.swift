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
        public let countText: NSAttributedString?
        public let dateText: NSAttributedString
        public let messageText: NSAttributedString?

        public init(
            emailText: NSAttributedString,
            countText: NSAttributedString?,
            dateText: NSAttributedString,
            messageText: NSAttributedString?
        ) {
            self.emailText = emailText
            self.countText = countText
            self.dateText = dateText
            self.messageText = messageText
        }
    }

    private let emailNode = ASTextNode2()
    private let countNode: ASTextNode2?
    private let dateNode = ASTextNode2()
    private lazy var messageNode: ASTextNode2? = ASTextNode2()
    private let separatorNode = ASDisplayNode()

    public init(input: Input) {
        countNode = input.countText.map({
            let node = ASTextNode2()
            node.attributedText = $0
            return node
        })
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
        let emailElement: ASLayoutElement = {
            guard let countNode = countNode else { return emailNode }
            emailNode.style.flexShrink = 1.0
            let spec = ASStackLayoutSpec.horizontal()
            spec.children = [emailNode, countNode]
            spec.spacing = 5
            return spec
        }()

        let nameLocationStack = ASStackLayoutSpec.vertical()
        nameLocationStack.spacing = 6
        nameLocationStack.style.flexShrink = 1.0
        nameLocationStack.style.flexGrow = 1.0
        separatorNode.style.flexGrow = 1.0
        separatorNode.style.preferredSize.height = 1.0

        if let messageNode = messageNode {
            nameLocationStack.children = [emailElement, messageNode]
        } else {
            nameLocationStack.children = [emailElement]
        }

        let headerStackSpec = ASStackLayoutSpec(
            direction: .horizontal,
            spacing: 8,
            justifyContent: .start,
            alignItems: .start,
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
