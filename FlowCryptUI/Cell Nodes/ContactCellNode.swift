//
//  ContactCellNode.swift
//  FlowCryptUI
//
//  Created by Anton Kharchevskyi on 22/08/2020.
//  Copyright © 2020 FlowCrypt Limited. All rights reserved.
//

import AsyncDisplayKit

public final class ContactCellNode: CellNode {
    public struct Input {
        let name: NSAttributedString?
        let email: NSAttributedString
        let insets: UIEdgeInsets
        let buttonImage: UIImage?

        public init(
            name: NSAttributedString?,
            email: NSAttributedString,
            insets: UIEdgeInsets,
            buttonImage: UIImage?
        ) {
            self.name = name
            self.email = email
            self.insets = insets
            self.buttonImage = buttonImage
        }
    }

    private let nameNode = ASTextNode2()
    private let emailNode = ASTextNode2()
    private let buttonNode = ASButtonNode()

    private let input: Input
    private let action: (() -> Void)?

    public init(input: Input, action: (() -> Void)?) {
        self.input = input
        self.action = action
        super.init()

        nameNode.attributedText = input.name
        emailNode.attributedText = input.email
        buttonNode.setImage(input.buttonImage, for: .normal)
        buttonNode.addTarget(self, action: #selector(handleButtonTap), forControlEvents: .touchUpInside)
    }

    @objc private func handleButtonTap() {
        action?()
    }

    public override func layoutSpecThatFits(_: ASSizeRange) -> ASLayoutSpec {
        let children: [ASLayoutElement]
        if input.name == nil {
            emailNode.style.flexGrow = 1
            children = [emailNode, buttonNode]
        } else {
            let nameStack = ASStackLayoutSpec(
                direction: .vertical,
                spacing: 8,
                justifyContent: .start,
                alignItems: .start,
                children: [nameNode, emailNode]
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
