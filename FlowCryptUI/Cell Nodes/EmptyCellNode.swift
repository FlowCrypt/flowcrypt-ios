//
//  EmptyCellNode.swift
//  FlowCryptUI
//
//  Created by Ioan Moldovan on 6/15/22
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import AsyncDisplayKit
import FlowCryptCommon
import UIKit

public final class EmptyCellNode: CellNode {
    public struct Input {
        let backgroundColor: UIColor
        let title: String
        let size: CGSize
        let imageName: String?
        let accessibilityIdentifier: String?

        public init(
            backgroundColor: UIColor,
            title: String,
            size: CGSize,
            imageName: String? = nil,
            accessibilityIdentifier: String? = nil
        ) {
            self.backgroundColor = backgroundColor
            self.title = title
            self.size = size
            self.imageName = imageName
            self.accessibilityIdentifier = accessibilityIdentifier
        }
    }

    private let size: CGSize
    private let textNode = ASTextNode2()
    private let imageNode: ASImageNode = {
        let imageNode = ASImageNode()
        imageNode.contentMode = .scaleAspectFit
        imageNode.style.preferredSize = CGSize(width: 100, height: 100)
        imageNode.alpha = 0.5
        return imageNode
    }()

    public init(input: Input) {
        self.size = input.size
        super.init()
        addSubnode(textNode)
        addSubnode(imageNode)
        textNode.attributedText = NSAttributedString.text(
            from: input.title,
            style: .medium(16),
            color: .lightGray,
            alignment: .center
        )
        let configuration = UIImage.SymbolConfiguration(pointSize: 100)
        imageNode.image = UIImage(systemName: input.imageName ?? "", withConfiguration: configuration)?.tinted(.main)
        backgroundColor = input.backgroundColor
        accessibilityIdentifier = input.accessibilityIdentifier
    }

    public override func layoutSpecThatFits(_: ASSizeRange) -> ASLayoutSpec {
        let spec = ASStackLayoutSpec(
            direction: .vertical,
            spacing: 16,
            justifyContent: .center,
            alignItems: .center,
            children: [imageNode, textNode]
        )
        spec.style.preferredSize = size
        return ASInsetLayoutSpec(
            insets: UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16),
            child: ASCenterLayoutSpec(child: spec)
        )
    }
}
