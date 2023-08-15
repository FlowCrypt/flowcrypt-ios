//
//  ThreadMessageDraftCellNode.swift
//  FlowCryptUI
//
//  Created by Ioan Moldovan on 8/14/23
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import AsyncDisplayKit
import LetterAvatarKit
import UIKit

public final class ThreadMessageDraftCellNode: CellNode {

    private lazy var avatarNode: ASImageNode = {
        let node = ASImageNode()
        let configuration = UIImage.SymbolConfiguration(pointSize: 20)
        node.image = UIImage(systemName: "envelope.open", withConfiguration: configuration)?.tinted(.white)
        node.cornerRadius = .Avatar.width / 2
        node.backgroundColor = .main
        node.contentMode = .center
        node.style.preferredSize = CGSize(width: .Avatar.width, height: .Avatar.height)
        return node
    }()

    private let draftBody: String
    private let messageIndex: Int
    private let sender: String
    private let action: (() -> Void)?

    private lazy var draftNode: LabelCellNode = {
        let node = LabelCellNode(
            input: .init(
                title: "draft".localized.attributed(color: .systemRed),
                text: draftBody.removingMailThreadQuote().attributed(color: .secondaryLabel),
                insets: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0),
                accessibilityIdentifier: "aid-draft-body-\(messageIndex)",
                labelAccessibilityIdentifier: "aid-draft-label-\(messageIndex)",
                buttonAccessibilityIdentifier: "aid-draft-delete-button-\(messageIndex)",
                actionButtonImageName: "trash",
                action: { [weak self] in
                    self?.action?()
                }
            )
        )
        node.style.flexGrow = 1.0
        node.style.flexShrink = 1.0
        return node
    }()

    public init(sender: String, draftBody: String, messageIndex: Int, action: (() -> Void)? = nil) {
        self.draftBody = draftBody
        self.sender = sender
        self.messageIndex = messageIndex
        self.action = action
    }

    override public func layoutSpecThatFits(_: ASSizeRange) -> ASLayoutSpec {
        let spec = ASStackLayoutSpec(
            direction: .horizontal,
            spacing: 10,
            justifyContent: .center,
            alignItems: .start,
            children: [avatarNode, draftNode]
        )
        return ASInsetLayoutSpec(
            insets: .deviceSpecificTextInsets(top: 16, bottom: 16),
            child: spec
        )
    }
}
