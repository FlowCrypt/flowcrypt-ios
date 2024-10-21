//
//  SecurityWarningNode.swift
//  FlowCrypt
//
//  Created by Ioan Moldovan on 9/26/24
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import AsyncDisplayKit

public final class SecurityWarningNode: CellNode {

    private lazy var subjectNode: ASTextNode2 = {
        let textNode = ASTextNode2()
        textNode.attributedText = "message_security_warning_subject".localized.attributed(.bold(18), color: .black, alignment: .left)
        textNode.accessibilityIdentifier = "aid-security-warning-subject-node"
        return textNode
    }()

    private lazy var messageNode: ASTextNode2 = {
        let textNode = ASTextNode2()
        textNode.attributedText = "message_security_warning_message".localized.attributed(.regular(15), color: .black, alignment: .left)
        textNode.accessibilityIdentifier = "aid-security-warning-message-node"
        return textNode
    }()

    override public init() {
        super.init()

        backgroundColor = UIColor(hex: "FABD03")
    }

    override public func layoutSpecThatFits(_: ASSizeRange) -> ASLayoutSpec {
        let stack = ASStackLayoutSpec.vertical()
        stack.children = [subjectNode, messageNode]
        stack.spacing = 10

        return ASInsetLayoutSpec(
            insets: .deviceSpecificTextInsets(top: 16, bottom: 16),
            child: stack
        )
    }
}
