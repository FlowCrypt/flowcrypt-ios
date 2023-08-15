//
//  InboxCellNode.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 01.10.2019.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import AsyncDisplayKit
import LetterAvatarKit
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

    private lazy var avatarNode: ASImageNode = {
        var emailString = input.emailText.string
        // extract the text that comes after "To:" because in `Sent` folder, emailText becomes `To: xx`
        // https://github.com/FlowCrypt/flowcrypt-ios/pull/2320#discussion_r1294448818
        if let range = emailString.range(of: "To: ") {
            emailString = String(emailString[range.upperBound...])
        }
        return getAvatarImage(text: emailString)
    }()

    private let emailNode = ASTextNode2()
    private let countNode: ASTextNode2?
    private let dateNode = ASTextNode2()
    private let separatorNode = ASDisplayNode()

    private lazy var messageNode = ASTextNode2()
    private lazy var badgeNode = ASTextNode()

    public init(input: Input) {
        countNode = input.countText.map {
            let node = ASTextNode2()
            node.attributedText = $0
            return node
        }
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
            badgeNode.textContainerInset = .init(top: 1, left: 6, bottom: 1, right: 6)
            badgeNode.attributedText = badgeText
            badgeNode.cornerRadius = 6
            badgeNode.clipsToBounds = true
            badgeNode.backgroundColor = .main
        }

        emailNode.maximumNumberOfLines = 1
        dateNode.maximumNumberOfLines = 1
        emailNode.truncationMode = .byTruncatingTail
        separatorNode.backgroundColor = .separator
        accessibilityIdentifier = "aid-inbox-item"
    }

    override public func layoutSpecThatFits(_: ASSizeRange) -> ASLayoutSpec {
        let emailElement: ASLayoutElement = {
            guard let countNode else { return emailNode }
            emailNode.style.flexShrink = 1.0
            let spec = ASStackLayoutSpec.horizontal()
            spec.children = [emailNode, countNode]
            spec.spacing = 5
            return spec
        }()

        let nameLocationStack = ASStackLayoutSpec.vertical()
        nameLocationStack.spacing = 4
        nameLocationStack.style.flexShrink = 1.0
        nameLocationStack.style.flexGrow = 1.0
        separatorNode.style.flexGrow = 1.0
        separatorNode.style.preferredSize.height = 0.5

        if input.badgeText != nil {
            messageNode.style.flexShrink = 1.0
            let messageStack = ASStackLayoutSpec.horizontal()
            messageStack.style.flexShrink = 1.0
            messageStack.alignItems = .center
            messageStack.spacing = 6
            messageStack.children = [messageNode, badgeNode]
            nameLocationStack.children = [emailElement, messageStack]
        } else {
            nameLocationStack.children = [emailElement, messageNode]
        }

        let headerStackSpec = ASStackLayoutSpec(
            direction: .horizontal,
            spacing: 8,
            justifyContent: .start,
            alignItems: .start,
            children: [avatarNode, nameLocationStack, dateNode]
        )

        let finalSpec = ASStackLayoutSpec.vertical()
        finalSpec.children = [headerStackSpec, separatorNode]
        finalSpec.spacing = 10
        return ASInsetLayoutSpec(
            insets: .deviceSpecificTextInsets(top: 12, bottom: 0),
            child: finalSpec
        )
    }
}
