//
//  LabelCellNode.swift
//  FlowCryptUI
//
//  Created by Roma Sosnovsky on 13/10/21
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import AsyncDisplayKit
import Foundation

public final class LabelCellNode: CellNode {
    public struct Input {
        let title: NSAttributedString
        let text: NSAttributedString
        let insets: UIEdgeInsets
        let spacing: CGFloat
        let accessibilityIdentifier: String?
        let labelAccessibilityIdentifier: String?

        public init(
            title: NSAttributedString,
            text: NSAttributedString,
            insets: UIEdgeInsets = .deviceSpecificTextInsets(top: 8, bottom: 8),
            spacing: CGFloat = 4,
            accessibilityIdentifier: String? = nil,
            labelAccessibilityIdentifier: String? = nil
        ) {
            self.title = title
            self.text = text
            self.insets = insets
            self.spacing = spacing
            self.accessibilityIdentifier = accessibilityIdentifier
            self.labelAccessibilityIdentifier = labelAccessibilityIdentifier
        }
    }

    private let titleNode = ASTextNode2()
    private let textNode = ASTextNode2()
    private let input: Input

    public init(input: Input) {
        self.input = input
        super.init()

        titleNode.attributedText = input.title
        titleNode.accessibilityIdentifier = input.labelAccessibilityIdentifier
        textNode.attributedText = input.text
        textNode.accessibilityIdentifier = input.accessibilityIdentifier
    }

    override public func layoutSpecThatFits(_: ASSizeRange) -> ASLayoutSpec {
        ASInsetLayoutSpec(
            insets: input.insets,
            child: ASStackLayoutSpec(
                direction: .vertical,
                spacing: input.spacing,
                justifyContent: .start,
                alignItems: .start,
                children: [titleNode, textNode]
            )
        )
    }
}
