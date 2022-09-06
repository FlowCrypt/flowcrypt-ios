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

        public init(text: NSAttributedString?,
                    color: UIColor,
                    image: UIImage?) {
            self.text = text
            self.color = color
            self.image = image
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
        buttonNode.accessibilityIdentifier = "aid-message-password-cell"

        buttonNode.setAttributedTitle(input.text, for: .normal)
        buttonNode.setImage(input.image, for: .normal)
        buttonNode.addTarget(self, action: #selector(onButtonTap), forControlEvents: .touchUpInside)
    }

    override public func layoutSpecThatFits(_: ASSizeRange) -> ASLayoutSpec {
        buttonNode.style.flexShrink = 1.0

        let spacer = ASLayoutSpec()
        spacer.style.flexGrow = 1.0

        let spec = ASStackLayoutSpec(
            direction: .horizontal,
            spacing: 4,
            justifyContent: .start,
            alignItems: .start,
            children: [buttonNode, spacer]
        )

        return ASInsetLayoutSpec(
            insets: UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8),
            child: spec
        )
    }

    @objc private func onButtonTap() {
        action?()
    }
}
