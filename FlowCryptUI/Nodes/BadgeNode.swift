//
//  BadgeNode.swift
//  FlowCryptUI
//
//  Created by Roma Sosnovsky on 12/11/21
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import AsyncDisplayKit

public final class BadgeNode: ASDisplayNode {
    public struct Input {
        public let icon: String?
        public let text: NSAttributedString?
        public let color: UIColor?
        public let textAccessibilityIdentifier: String

        public init(icon: String?,
                    text: NSAttributedString?,
                    color: UIColor?,
                    textAccessibilityIdentifier: String) {
            self.icon = icon
            self.text = text
            self.color = color
            self.textAccessibilityIdentifier = textAccessibilityIdentifier
        }
    }

    private lazy var iconNode: ASImageNode? = {
        guard let icon = input.icon else { return nil }
        let imageNode = ASImageNode()
        let configuration = UIImage.SymbolConfiguration(pointSize: 10, weight: .medium)
        imageNode.image = UIImage(systemName: icon, withConfiguration: configuration)
        imageNode.imageModificationBlock = ASImageNodeTintColorModificationBlock(.white)
        return imageNode
    }()

    private let textNode = ASTextNode2()
    private let input: BadgeNode.Input

    init(input: BadgeNode.Input) {
        self.input = input
        super.init()

        automaticallyManagesSubnodes = true

        textNode.attributedText = input.text
        textNode.accessibilityIdentifier = input.textAccessibilityIdentifier
        backgroundColor = input.color
        cornerRadius = 4
    }

    override public func layoutSpecThatFits(_: ASSizeRange) -> ASLayoutSpec {
        let contentSpec = ASStackLayoutSpec(
            direction: .horizontal,
            spacing: 2,
            justifyContent: .spaceBetween,
            alignItems: .center,
            children: [iconNode, textNode].compactMap { $0 }
        )

        return ASInsetLayoutSpec(
            insets: UIEdgeInsets(top: 2, left: 4, bottom: 2, right: 4),
            child: contentSpec
        )
    }
}
