//
//  InboxCellNode.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 01.10.2019.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import AsyncDisplayKit
import UIKit

public final class InboxCellNode: CellNode {
    public struct Input {
        public let emailText: NSAttributedString
        public let countText: NSAttributedString?
        public let dateText: NSAttributedString
        public let messageText: NSAttributedString?
        public let badgeText: NSAttributedString?

        public init(
            emailText: NSAttributedString,
            countText: NSAttributedString?,
            dateText: NSAttributedString,
            messageText: NSAttributedString?,
            badgeText: NSAttributedString?
        ) {
            self.emailText = emailText
            self.countText = countText
            self.dateText = dateText
            self.messageText = messageText
            self.badgeText = badgeText
        }
    }

    private let input: Input

    private let emailNode = ASTextNode2()
    private let countNode: ASTextNode2?
    private let dateNode = ASTextNode2()
    private lazy var messageNode = ASTextNode2()
    private lazy var badgeNode = ASTextNode2()
    private let separatorNode = ASDisplayNode()

    public init(input: Input) {
        countNode = input.countText.map({
            let node = ASTextNode2()
            node.attributedText = $0
            return node
        })
        self.input = input

        super.init()

        emailNode.attributedText = input.emailText
        dateNode.attributedText = input.dateText

        if let message = input.messageText {
            messageNode.attributedText = message
            messageNode.maximumNumberOfLines = 1
            messageNode.truncationMode = .byTruncatingTail
        }

        if let badgeText = input.badgeText {
            badgeNode.attributedText = badgeText
            badgeNode.cornerRadius = 6
            badgeNode.clipsToBounds = true
        }

        emailNode.maximumNumberOfLines = 1
        dateNode.maximumNumberOfLines = 1
        emailNode.truncationMode = .byTruncatingTail
        separatorNode.backgroundColor = .lightGray
        accessibilityIdentifier = "aid-inbox-item"
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

        let badgeStack = ASStackLayoutSpec.horizontal()
        badgeStack.alignItems = .center
        badgeStack.spacing = 4
        badgeStack.children = [messageNode, badgeNode]

        let nameLocationStack = ASStackLayoutSpec.vertical()
        nameLocationStack.spacing = 6
        nameLocationStack.style.flexShrink = 1.0
        nameLocationStack.style.flexGrow = 1.0
        separatorNode.style.flexGrow = 1.0
        separatorNode.style.preferredSize.height = 1.0

        nameLocationStack.children = [emailElement, badgeStack]

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
            insets: .deviceSpecificTextInsets(top: 8, bottom: 8),
            child: finalSpec
        )
    }
}
