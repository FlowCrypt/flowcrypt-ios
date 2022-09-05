//
//  MenuNode.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 18.10.2019.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import AsyncDisplayKit

/// Node for representing text and optional image
public final class InfoCellNode: CellNode {
    public struct Input {
        let attributedText: NSAttributedString
        let image: UIImage?
        let insets: UIEdgeInsets
        let backgroundColor: UIColor?
        let accessibilityIdentifier: String?

        public init(
            attributedText: NSAttributedString,
            image: UIImage? = nil,
            insets: UIEdgeInsets = .deviceSpecificTextInsets(top: 8, bottom: 8),
            backgroundColor: UIColor? = nil,
            accessibilityIdentifier: String? = nil
        ) {
            self.attributedText = attributedText
            self.image = image
            self.insets = insets
            self.backgroundColor = backgroundColor
            self.accessibilityIdentifier = accessibilityIdentifier
        }
    }

    private let textNode = ASTextNode2()
    private let imageNode = ASImageNode()
    private let input: Input?

    public init(input: Input?) {
        self.input = input
        super.init()
        self.textNode.attributedText = input?.attributedText
        self.textNode.isAccessibilityElement = true
        self.textNode.accessibilityIdentifier = input?.accessibilityIdentifier

        self.imageNode.image = input?.image
        self.imageNode.contentMode = .scaleAspectFit
        self.automaticallyManagesSubnodes = true

        if let backgroundColor = input?.backgroundColor {
            self.backgroundColor = backgroundColor
        }
    }

    override public func layoutSpecThatFits(_: ASSizeRange) -> ASLayoutSpec {
        guard imageNode.image != nil else {
            return ASInsetLayoutSpec(
                insets: input?.insets ?? .zero,
                child: textNode
            )
        }

        imageNode.style.preferredSize = CGSize(width: 24, height: 24)
        return ASInsetLayoutSpec(
            insets: input?.insets ?? .zero,
            child: ASStackLayoutSpec.horizontal().then {
                $0.spacing = 6.0
                $0.children = [imageNode, textNode]
                $0.alignItems = .center
            }
        )
    }
}
