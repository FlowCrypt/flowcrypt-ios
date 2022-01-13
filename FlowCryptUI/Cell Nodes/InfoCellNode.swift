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
            image: UIImage?,
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
        self.automaticallyManagesSubnodes = true
        
        if let backgroundColor = input?.backgroundColor {
            self.backgroundColor = backgroundColor
        }
    }

    public override func layoutSpecThatFits(_: ASSizeRange) -> ASLayoutSpec {
        imageNode.style.preferredSize = imageNode.image != nil
            ? CGSize(width: 24, height: 24)
            : .zero

        return ASInsetLayoutSpec(
            insets: input?.insets ?? .zero,
            child: ASStackLayoutSpec.horizontal().then {
                $0.spacing = imageNode.image != nil ? 6.0 : 0.0
                $0.children = [imageNode, textNode]
                $0.alignItems = .center
            }
        )
    }
}
