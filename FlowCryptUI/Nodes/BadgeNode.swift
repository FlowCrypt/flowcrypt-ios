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
        public let additionalText: NSAttributedString?
        public let color: UIColor?
        public let textAccessibilityIdentifier: String
        public let additionalTextAccessibilityIdentifier: String?

        public init(icon: String?,
                    text: NSAttributedString?,
                    additionalText: NSAttributedString? = nil,
                    color: UIColor?,
                    textAccessibilityIdentifier: String,
                    additionalTextAccessibilityIdentifier: String? = nil) {
            self.icon = icon
            self.text = text
            self.additionalText = additionalText
            self.color = color
            self.textAccessibilityIdentifier = textAccessibilityIdentifier
            self.additionalTextAccessibilityIdentifier = additionalTextAccessibilityIdentifier
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
    private let additionalTextNode = ASTextNode2()
    private let input: BadgeNode.Input
    private var showAdditionalText = false

    init(input: BadgeNode.Input) {
        self.input = input
        super.init()

        automaticallyManagesSubnodes = true

        textNode.attributedText = input.text
        additionalTextNode.attributedText = input.additionalText
        textNode.accessibilityIdentifier = input.textAccessibilityIdentifier
        additionalTextNode.accessibilityIdentifier = input.additionalTextAccessibilityIdentifier
        backgroundColor = input.color
        cornerRadius = 4
        DispatchQueue.main.async {
            self.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.handleTap)))
        }
    }

    @objc private func handleTap() {
        if input.additionalText != nil {
            showAdditionalText = !showAdditionalText
            setNeedsLayout()
        }
    }

    override public func layoutSpecThatFits(_: ASSizeRange) -> ASLayoutSpec {
        let textSpec = ASStackLayoutSpec(
            direction: .vertical,
            spacing: 5.0,
            justifyContent: .start,
            alignItems: .start,
            children: showAdditionalText ? [textNode, additionalTextNode] : [textNode]
        )
        let contentSpec = ASStackLayoutSpec(
            direction: .horizontal,
            spacing: 2,
            justifyContent: .spaceBetween,
            alignItems: .center,
            children: [iconNode, textSpec].compactMap { $0 }
        )

        return ASInsetLayoutSpec(
            insets: UIEdgeInsets(top: 2, left: 4, bottom: 2, right: 4),
            child: contentSpec
        )
    }
}
