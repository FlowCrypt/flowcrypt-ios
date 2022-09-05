//
//  ComposeRecipientPopupNameNode.swift
//  FlowCryptUI
//
//  Created by Ioan Moldovan on 3/31/22
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import AsyncDisplayKit

public final class ComposeRecipientPopupNameNode: CellNode {

    private let email: String
    private let name: String?

    private lazy var nameNode: ASTextNode2 = {
        let textNode = ASTextNode2()
        textNode.attributedText = name?.attributed(.regular(18), color: .darkGray, alignment: .left)
        textNode.accessibilityIdentifier = "aid-recipient-popup-name-node"
        return textNode
    }()

    private lazy var emailNode: ASTextNode2 = {
        let textNode = ASTextNode2()
        if name != nil {
            textNode.attributedText = email.attributed(.regular(15), color: .lightGray, alignment: .left)
        } else {
            textNode.attributedText = email.attributed(.regular(18), color: .darkGray, alignment: .left)
        }
        textNode.accessibilityIdentifier = "aid-recipient-popup-email-node"
        return textNode
    }()

    public init(name: String?, email: String) {
        self.name = name
        self.email = email
        super.init()
    }

    override public func layoutSpecThatFits(_: ASSizeRange) -> ASLayoutSpec {
        let stack = ASStackLayoutSpec.vertical()
        if name != nil {
            stack.children = [nameNode, emailNode]
        } else {
            stack.children = [emailNode]
        }
        stack.spacing = 10
        stack.style.preferredSize.height = 50
        stack.verticalAlignment = .center

        return ASInsetLayoutSpec(
            insets: .deviceSpecificTextInsets(top: 16, bottom: 4),
            child: stack
        )
    }
}
