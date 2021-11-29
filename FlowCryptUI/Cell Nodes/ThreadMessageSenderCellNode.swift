//
//  ThreadMessageSenderCellNode.swift
//  FlowCryptUI
//
//  Created by Roma Sosnovsky on 06/11/21
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import AsyncDisplayKit
import UIKit

public final class ThreadMessageSenderCellNode: CellNode {
    public struct Input {
        public let encryptionBadge: BadgeNode.Input
        public let signatureBadge: BadgeNode.Input?
        public let sender: NSAttributedString
        public let recipient: NSAttributedString
        public let date: NSAttributedString?
        public let isExpanded: Bool
        public let buttonColor: UIColor
        public let nodeInsets: UIEdgeInsets

        public init(encryptionBadge: BadgeNode.Input,
                    signatureBadge: BadgeNode.Input?,
                    sender: NSAttributedString,
                    recipient: NSAttributedString,
                    date: NSAttributedString,
                    isExpanded: Bool,
                    buttonColor: UIColor,
                    nodeInsets: UIEdgeInsets) {
            self.encryptionBadge = encryptionBadge
            self.signatureBadge = signatureBadge
            self.sender = sender
            self.recipient = recipient
            self.date = date
            self.isExpanded = isExpanded
            self.buttonColor = buttonColor
            self.nodeInsets = nodeInsets
        }

        var replyImage: UIImage? { createButtonImage("arrow.turn.up.left") }
        var menuImage: UIImage? { createButtonImage("ellipsis") }
        var expandImage: UIImage? { createButtonImage("chevron.down") }

        private func createButtonImage(_ systemName: String, pointSize: CGFloat = 18) -> UIImage? {
            let configuration = UIImage.SymbolConfiguration(pointSize: pointSize)
            return UIImage(systemName: systemName, withConfiguration: configuration)
        }
    }

    private lazy var encryptionNode: BadgeNode = {
        return BadgeNode(input: input.encryptionBadge)
    }()

    private lazy var signatureNode: BadgeNode? = {
        return input.signatureBadge.map(BadgeNode.init)
    }()

    private let senderNode = ASTextNode2()
    private let recipientNode = ASTextNode2()
    private let dateNode = ASTextNode2()

    public private(set) var replyNode = ASButtonNode()
    public private(set) var menuNode = ASButtonNode()
    public private(set) var expandNode = ASImageNode()

    private let input: ThreadMessageSenderCellNode.Input
    private var onReplyTap: ((ThreadMessageSenderCellNode) -> Void)?
    private var onMenuTap: ((ThreadMessageSenderCellNode) -> Void)?

    public init(input: ThreadMessageSenderCellNode.Input,
                onReplyTap: ((ThreadMessageSenderCellNode) -> Void)?,
                onMenuTap: ((ThreadMessageSenderCellNode) -> Void)?) {
        self.input = input
        self.onReplyTap = onReplyTap
        self.onMenuTap = onMenuTap
        super.init()
        automaticallyManagesSubnodes = true

        senderNode.attributedText = input.sender
        senderNode.accessibilityIdentifier = "messageSenderLabel"

        recipientNode.attributedText = input.recipient
        recipientNode.accessibilityIdentifier = "messageRecipientLabel"

        dateNode.attributedText = input.date

        setupReplyNode()
        setupMenuNode()
        setupExpandNode()
    }

    private func setupReplyNode() {
        setup(buttonNode: replyNode,
              with: input.replyImage,
              action: #selector(onReplyNodeTap),
              accessibilityIdentifier: "replyButton")
    }

    private func setupMenuNode() {
        setup(buttonNode: menuNode,
              with: input.menuImage,
              action: #selector(onMenuNodeTap),
              accessibilityIdentifier: "messageMenuButton")
    }

    private func setup(buttonNode node: ASButtonNode,
                       with image: UIImage?,
                       action: Selector,
                       accessibilityIdentifier: String) {
        node.setImage(image, for: .normal)
        node.imageNode.imageModificationBlock = ASImageNodeTintColorModificationBlock(input.buttonColor)
        node.addTarget(self, action: action, forControlEvents: .touchUpInside)
        node.accessibilityIdentifier = accessibilityIdentifier
    }

    private func setupExpandNode() {
        expandNode.image = input.expandImage
        expandNode.imageModificationBlock = ASImageNodeTintColorModificationBlock(input.buttonColor)
        expandNode.contentMode = .center
    }

    @objc private func onReplyNodeTap() {
        onReplyTap?(self)
    }

    @objc private func onMenuNodeTap() {
        onMenuTap?(self)
    }

    public override func layoutSpecThatFits(_: ASSizeRange) -> ASLayoutSpec {
        replyNode.style.preferredSize = CGSize(width: 44, height: 44)
        menuNode.style.preferredSize = CGSize(width: 36, height: 44)
        expandNode.style.preferredSize = CGSize(width: 36, height: 44)

        let infoNode = ASStackLayoutSpec(
            direction: .vertical,
            spacing: 4,
            justifyContent: .spaceBetween,
            alignItems: .start,
            children: [senderNode, recipientNode, dateNode]
        )
        infoNode.style.flexGrow = 1
        infoNode.style.flexShrink = 1

        let contentSpec: ASStackLayoutSpec

        if input.isExpanded {
            let senderSpec = ASStackLayoutSpec(
                direction: .horizontal,
                spacing: 2,
                justifyContent: .spaceBetween,
                alignItems: .start,
                children: [infoNode, replyNode, menuNode]
            )

            let spacer = ASLayoutSpec()
            spacer.style.flexGrow = 1.0

            let signatureSpec = ASStackLayoutSpec(
                direction: .horizontal,
                spacing: 4,
                justifyContent: .spaceBetween,
                alignItems: .start,
                children: [encryptionNode, signatureNode, spacer].compactMap { $0 }
            )

            contentSpec = ASStackLayoutSpec(
                direction: .vertical,
                spacing: 4,
                justifyContent: .spaceBetween,
                alignItems: .stretch,
                children: [senderSpec, signatureSpec]
            )
        } else {
            contentSpec = ASStackLayoutSpec(
                direction: .horizontal,
                spacing: 4,
                justifyContent: .spaceBetween,
                alignItems: .start,
                children: [infoNode, expandNode]
            )
        }

        return ASInsetLayoutSpec(
            insets: input.nodeInsets,
            child: contentSpec
        )
    }
}
