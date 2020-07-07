//
//  MessageSenderNode.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 06.11.2019.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import AsyncDisplayKit
import FlowCryptCommon

public final class MessageSenderNode: CellNode {
    public typealias ButtonAction = () -> Void

    private let textNode = ASTextNode2()
    private let buttonNode = ASButtonNode()
    private let onTap: ButtonAction?

    public init(_ text: NSAttributedString? = nil, action: ButtonAction? = nil) {
        onTap = action
        super.init()
        textNode.attributedText = text
        buttonNode.setImage(UIImage(named: "reply-all")?.tinted(.main), for: .normal)
        buttonNode.addTarget(self, action: #selector(tapHandler), forControlEvents: .touchUpInside)
    }

    @objc private func tapHandler() {
        onTap?()
    }

    public override func layoutSpecThatFits(_: ASSizeRange) -> ASLayoutSpec {
        textNode.style.flexGrow = 1.0
        buttonNode.style.preferredSize = CGSize(width: 50, height: 50)
        return ASInsetLayoutSpec(
            insets: UIEdgeInsets(top: 2, left: 8, bottom: 0, right: 2),
            child: ASStackLayoutSpec(
                direction: .horizontal,
                spacing: 4,
                justifyContent: .start,
                alignItems: .center,
                children: [textNode, buttonNode]
            )
        )
    }
}
