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
        public let recipientLabel: NSAttributedString
        public let recipients: [MessageRecipient]
        public let ccRecipients: [MessageRecipient]
        public let bccRecipients: [MessageRecipient]
        public let date: NSAttributedString?
        public let isExpanded: Bool
        public let shouldShowRecipientsList: Bool
        public let buttonColor: UIColor
        public let nodeInsets: UIEdgeInsets

        public init(encryptionBadge: BadgeNode.Input,
                    signatureBadge: BadgeNode.Input?,
                    sender: NSAttributedString,
                    recipientLabel: NSAttributedString,
                    recipients: [(String?, String)],
                    ccRecipients: [(String?, String)],
                    bccRecipients: [(String?, String)],
                    date: NSAttributedString,
                    isExpanded: Bool,
                    shouldShowRecipientsList: Bool,
                    buttonColor: UIColor,
                    nodeInsets: UIEdgeInsets) {
            self.encryptionBadge = encryptionBadge
            self.signatureBadge = signatureBadge
            self.sender = sender
            self.recipientLabel = recipientLabel
            self.recipients = recipients
            self.ccRecipients = ccRecipients
            self.bccRecipients = bccRecipients
            self.date = date
            self.isExpanded = isExpanded
            self.shouldShowRecipientsList = shouldShowRecipientsList
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

    private lazy var recipientsListNode: ASDisplayNode = {
        MessageRecipientsNode(
            input: .init(
                recipients: input.recipients,
                ccRecipients: input.ccRecipients,
                bccRecipients: input.bccRecipients
            )
        )
    }()

    private let senderNode = ASTextNode2()
    private let recipientButtonNode = ASButtonNode()
    private let dateNode = ASTextNode2()

    public private(set) var replyNode = ASButtonNode()
    public private(set) var menuNode = ASButtonNode()
    public private(set) var expandNode = ASImageNode()

    private let input: ThreadMessageSenderCellNode.Input

    private let onReplyTap: ((ThreadMessageSenderCellNode) -> Void)?
    private let onMenuTap: ((ThreadMessageSenderCellNode) -> Void)?
    private let onRecipientsTap: ((ThreadMessageSenderCellNode) -> Void)?

    public init(input: ThreadMessageSenderCellNode.Input,
                onReplyTap: ((ThreadMessageSenderCellNode) -> Void)?,
                onMenuTap: ((ThreadMessageSenderCellNode) -> Void)?,
                onRecipientsTap: ((ThreadMessageSenderCellNode) -> Void)?) {
        self.input = input
        self.onReplyTap = onReplyTap
        self.onMenuTap = onMenuTap
        self.onRecipientsTap = onRecipientsTap

        super.init()
        automaticallyManagesSubnodes = true

        senderNode.attributedText = input.sender
        senderNode.accessibilityIdentifier = "messageSenderLabel"

        dateNode.attributedText = input.date

        setupRecipientButton()
        setupReplyNode()
        setupMenuNode()
        setupExpandNode()
    }

    private func setupRecipientButton() {
        let imageName = input.shouldShowRecipientsList ? "chevron.up" : "chevron.down"
        let configuration = UIImage.SymbolConfiguration(font: .systemFont(ofSize: 12, weight: .medium))
        recipientButtonNode.setImage(UIImage(systemName: imageName, withConfiguration: configuration), for: .normal)
        recipientButtonNode.setAttributedTitle(input.recipientLabel, for: .normal)
        recipientButtonNode.titleNode.maximumNumberOfLines = 1
        recipientButtonNode.titleNode.truncationMode = .byTruncatingTail
        recipientButtonNode.imageAlignment = .end
        recipientButtonNode.imageNode.imageModificationBlock = ASImageNodeTintColorModificationBlock(.secondaryLabel)
        recipientButtonNode.contentSpacing = 4
        recipientButtonNode.addTarget(self, action: #selector(onRecipientsNodeTap), forControlEvents: .touchUpInside)
        recipientButtonNode.accessibilityIdentifier = "messageRecipientButton"
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

    @objc private func onRecipientsNodeTap() {
        onRecipientsTap?(self)
    }

    public override func layoutSpecThatFits(_: ASSizeRange) -> ASLayoutSpec {
        replyNode.style.preferredSize = CGSize(width: 44, height: 44)
        menuNode.style.preferredSize = CGSize(width: 36, height: 44)
        expandNode.style.preferredSize = CGSize(width: 36, height: 44)

        let infoChildren: [ASLayoutElement]
        if input.isExpanded {
            if input.shouldShowRecipientsList {
                infoChildren = [senderNode, recipientButtonNode]
            } else {
                infoChildren = [senderNode, recipientButtonNode, dateNode]
            }
        } else {
            infoChildren = [senderNode, dateNode]
        }

        let infoNode = ASStackLayoutSpec(
            direction: .vertical,
            spacing: 6,
            justifyContent: .spaceBetween,
            alignItems: .start,
            children: infoChildren
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

            if input.shouldShowRecipientsList {
                let recipientsSpec = ASStackLayoutSpec(
                    direction: .vertical,
                    spacing: 4,
                    justifyContent: .spaceBetween,
                    alignItems: .start,
                    children: [recipientsListNode, dateNode]
                )

                contentSpec = ASStackLayoutSpec(
                    direction: .vertical,
                    spacing: 8,
                    justifyContent: .spaceBetween,
                    alignItems: .stretch,
                    children: [senderSpec, recipientsSpec, signatureSpec]
                )
            } else {
                contentSpec = ASStackLayoutSpec(
                    direction: .vertical,
                    spacing: 4,
                    justifyContent: .spaceBetween,
                    alignItems: .stretch,
                    children: [senderSpec, signatureSpec]
                )
            }

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
