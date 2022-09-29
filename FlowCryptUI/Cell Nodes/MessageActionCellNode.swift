//
//  MessageActionCellNode.swift
//  FlowCryptUI
//
//  Created by Roma Sosnovsky on 15/12/21
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import AsyncDisplayKit
import UIKit

public final class MessageActionCellNode: CellNode {
    public struct Input {
        let text: NSAttributedString?
        let color: UIColor
        let image: UIImage?
        let accessibilityIdentifier: String?

        public init(
            text: NSAttributedString?,
            color: UIColor,
            image: UIImage?,
            accessibilityIdentifier: String?
        ) {
            self.text = text
            self.color = color
            self.image = image
            self.accessibilityIdentifier = accessibilityIdentifier
        }
    }

    private let input: Input

    private let buttonNode = ASButtonNode()
    private let action: (() -> Void)?

    public init(input: Input, action: (() -> Void)?) {
        self.input = input
        self.action = action

        super.init()

        automaticallyManagesSubnodes = true

        setupButtonNode()
    }

    private func setupButtonNode() {
        buttonNode.contentEdgeInsets = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)
        buttonNode.borderColor = input.color.cgColor
        buttonNode.borderWidth = 1
        buttonNode.cornerRadius = 6
        buttonNode.contentHorizontalAlignment = .left
        buttonNode.accessibilityIdentifier = input.accessibilityIdentifier

        buttonNode.setAttributedTitle(input.text, for: .normal)
        buttonNode.setImage(input.image, for: .normal)
        buttonNode.addTarget(self, action: #selector(onButtonTap), forControlEvents: .touchUpInside)
    }

    override public func layoutSpecThatFits(_: ASSizeRange) -> ASLayoutSpec {
        buttonNode.style.flexGrow = 1.0

        return ASInsetLayoutSpec(
            insets: UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8),
            child: buttonNode
        )
    }

    @objc private func onButtonTap() {
        action?()
    }
}
