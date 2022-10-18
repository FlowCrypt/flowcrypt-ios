//
//  LabelCellNode.swift
//  FlowCryptUI
//
//  Created by Roma Sosnovsky on 13/10/21
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import AsyncDisplayKit

public final class LabelCellNode: CellNode {
    public struct Input {
        let title: NSAttributedString
        let text: NSAttributedString
        let insets: UIEdgeInsets
        let spacing: CGFloat
        let accessibilityIdentifier: String?
        let labelAccessibilityIdentifier: String?
        let buttonAccessibilityIdentifier: String?
        let actionButtonImageName: String?
        let action: (() -> Void)?

        public init(
            title: NSAttributedString,
            text: NSAttributedString,
            insets: UIEdgeInsets = .deviceSpecificTextInsets(top: 8, bottom: 8),
            spacing: CGFloat = 4,
            accessibilityIdentifier: String? = nil,
            labelAccessibilityIdentifier: String? = nil,
            buttonAccessibilityIdentifier: String? = nil,
            actionButtonImageName: String? = nil,
            action: (() -> Void)? = nil
        ) {
            self.title = title
            self.text = text
            self.insets = insets
            self.spacing = spacing
            self.accessibilityIdentifier = accessibilityIdentifier
            self.labelAccessibilityIdentifier = labelAccessibilityIdentifier
            self.buttonAccessibilityIdentifier = buttonAccessibilityIdentifier
            self.actionButtonImageName = actionButtonImageName
            self.action = action
        }
    }

    private let titleNode = ASTextNode2()
    private let textNode = ASTextNode2()
    private let actionButtonNode = ASButtonNode()
    private let input: Input
    private var action: (() -> Void)?

    public init(input: Input) {
        self.input = input
        super.init()

        titleNode.attributedText = input.title
        titleNode.accessibilityIdentifier = input.labelAccessibilityIdentifier
        textNode.attributedText = input.text
        textNode.accessibilityIdentifier = input.accessibilityIdentifier

        action = input.action
        actionButtonNode.addTarget(self, action: #selector(onActionButtonTap), forControlEvents: .touchUpInside)

        if let imageName = input.actionButtonImageName {
            actionButtonNode.accessibilityIdentifier = input.buttonAccessibilityIdentifier
            actionButtonNode.setImage(UIImage(systemName: imageName)?.tinted(.secondaryLabel), for: .normal)
        }
    }

    @objc private func onActionButtonTap() {
        action?()
    }

    override public func layoutSpecThatFits(_: ASSizeRange) -> ASLayoutSpec {
        let labelSpec = ASStackLayoutSpec(
            direction: .vertical,
            spacing: input.spacing,
            justifyContent: .start,
            alignItems: .start,
            children: [titleNode, textNode]
        )
        if action != nil {
            actionButtonNode.style.preferredSize = CGSize(width: 36, height: 44)

            let spec = ASStackLayoutSpec(
                direction: .horizontal,
                spacing: input.spacing,
                justifyContent: .spaceBetween,
                alignItems: .stretch,
                children: [labelSpec, actionButtonNode]
            )
            labelSpec.style.flexShrink = 1
            return ASInsetLayoutSpec(
                insets: input.insets,
                child: spec
            )
        } else {
            return ASInsetLayoutSpec(
                insets: input.insets,
                child: labelSpec
            )
        }
    }
}
