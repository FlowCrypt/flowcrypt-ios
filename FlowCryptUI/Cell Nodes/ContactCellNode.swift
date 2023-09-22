//
//  ContactCellNode.swift
//  FlowCryptUI
//
//  Created by Anton Kharchevskyi on 22/08/2020.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import AsyncDisplayKit

public final class ContactCellNode: CellNode {
    public struct Input {
        let name: NSAttributedString?
        let email: NSAttributedString
        let keys: NSAttributedString
        let insets: UIEdgeInsets
        let buttonImage: UIImage?

        public init(
            name: NSAttributedString?,
            email: NSAttributedString,
            keys: NSAttributedString,
            insets: UIEdgeInsets,
            buttonImage: UIImage?
        ) {
            self.name = name
            self.email = email
            self.keys = keys
            self.insets = insets
            self.buttonImage = buttonImage
        }
    }

    private let nameNode = ASTextNode2()
    private let emailNode = ASTextNode2()
    private let keysNode = ASTextNode2()
    private let buttonNode = ASButtonNode()

    private let input: Input
    public var action: (() -> Void)?

    public init(input: Input) {
        self.input = input
        super.init()

        accessibilityIdentifier = "aid-contact-item"
        nameNode.attributedText = input.name
        emailNode.attributedText = input.email
        keysNode.attributedText = input.keys
        buttonNode.setImage(input.buttonImage, for: .normal)
        buttonNode.addTarget(self, action: #selector(handleButtonTap), forControlEvents: .touchUpInside)
    }

    @objc private func handleButtonTap() {
        action?()
    }

    override public func layoutSpecThatFits(_: ASSizeRange) -> ASLayoutSpec {
        let children: [ASLayoutElement]
        if input.name == nil {
            emailNode.style.flexGrow = 1
            children = [emailNode, buttonNode]
        } else {
            let infoStack = ASStackLayoutSpec(
                direction: .horizontal,
                spacing: 4,
                justifyContent: .start,
                alignItems: .start,
                children: [emailNode, keysNode]
            )
            let nameStack = ASStackLayoutSpec(
                direction: .vertical,
                spacing: 8,
                justifyContent: .start,
                alignItems: .start,
                children: [nameNode, infoStack]
            )
            nameStack.style.flexGrow = 1
            children = [nameStack, buttonNode]
        }
        return ASInsetLayoutSpec(
            insets: input.insets,
            child: ASStackLayoutSpec(
                direction: .horizontal,
                spacing: 8,
                justifyContent: .start,
                alignItems: .stretch,
                children: children
            )
        )
    }
}
