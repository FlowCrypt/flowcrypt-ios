//
//  ThreadMessageInfoCellNode.swift
//  FlowCryptUI
//
//  Created by Roma Sosnovsky on 06/11/21
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import AsyncDisplayKit
import UIKit

public final class ThreadMessageInfoCellNode: CellNode {
    // MARK: - Input
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

    // MARK: - Node State
    private enum InfoNodeState {
        case collapsed, expanded, expandedWithRecipients
    }

    private var nodeState: InfoNodeState {
        guard input.isExpanded else { return .collapsed }
        guard input.shouldShowRecipientsList else { return .expanded }
        return .expandedWithRecipients
    }

    // MARK: - Specs
    private lazy var headerSpec: ASStackLayoutSpec = {
        ASStackLayoutSpec(
            direction: .horizontal,
            spacing: 2,
            justifyContent: .spaceBetween,
            alignItems: .start,
            children: [infoSpec, replyNode, menuNode]
        )
    }()

    private lazy var infoSpec: ASStackLayoutSpec = {
        let node = ASStackLayoutSpec(
            direction: .vertical,
            spacing: 6,
            justifyContent: .spaceBetween,
            alignItems: .start,
            children: infoSpecChildren
        )
        node.style.flexGrow = 1
        node.style.flexShrink = 1
        return node
    }()

    private var infoSpecChildren: [ASLayoutElement] {
        switch nodeState {
        case .collapsed:
            return [senderNode, dateNode]
        case .expanded:
            return [senderNode, recipientButtonNode, dateNode]
        case .expandedWithRecipients:
            return [senderNode, recipientButtonNode]
        }
    }

    private lazy var recipientsSpec: ASStackLayoutSpec = {
        ASStackLayoutSpec(
            direction: .vertical,
            spacing: 4,
            justifyContent: .spaceBetween,
            alignItems: .start,
            children: [recipientsListNode, dateNode]
        )
    }()

    private lazy var encryptionInfoSpec: ASStackLayoutSpec = {
        let spacer = ASLayoutSpec()
        spacer.style.flexGrow = 1.0

        return ASStackLayoutSpec(
            direction: .horizontal,
            spacing: 4,
            justifyContent: .spaceBetween,
            alignItems: .start,
            children: [encryptionNode, signatureNode, spacer].compactMap { $0 }
        )
    }()

    // MARK: - Nodes
    private let senderNode = ASTextNode2()
    private let recipientButtonNode = ASButtonNode()
    private let dateNode = ASTextNode2()

    private let replyNode = ASButtonNode()
    private let menuNode = ASButtonNode()
    public private(set) var expandNode = ASImageNode()

    private lazy var recipientsListNode: ASDisplayNode = {
        MessageRecipientsNode(
            input: .init(
                recipients: input.recipients,
                ccRecipients: input.ccRecipients,
                bccRecipients: input.bccRecipients
            )
        )
    }()

    private lazy var encryptionNode: BadgeNode = {
        BadgeNode(input: input.encryptionBadge)
    }()

    private lazy var signatureNode: BadgeNode? = {
        input.signatureBadge.map(BadgeNode.init)
    }()

    // MARK: - Properties
    private let input: ThreadMessageInfoCellNode.Input

    private let onReplyTap: ((ThreadMessageInfoCellNode) -> Void)?
    private let onMenuTap: ((ThreadMessageInfoCellNode) -> Void)?
    private let onRecipientsTap: ((ThreadMessageInfoCellNode) -> Void)?

    private var recipientButtonImage: UIImage? {
        let configuration = UIImage.SymbolConfiguration(font: .systemFont(ofSize: 12, weight: .medium))
        let imageName = input.shouldShowRecipientsList ? "chevron.up" : "chevron.down"
        return UIImage(systemName: imageName, withConfiguration: configuration)
    }

    // MARK: - Init
    public init(input: ThreadMessageInfoCellNode.Input,
                onReplyTap: ((ThreadMessageInfoCellNode) -> Void)?,
                onMenuTap: ((ThreadMessageInfoCellNode) -> Void)?,
                onRecipientsTap: ((ThreadMessageInfoCellNode) -> Void)?) {
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

    // MARK: - Setup
    private func setupRecipientButton() {
        recipientButtonNode.setImage(recipientButtonImage, for: .normal)
        recipientButtonNode.imageAlignment = .end
        recipientButtonNode.imageNode.imageModificationBlock = ASImageNodeTintColorModificationBlock(.secondaryLabel)

        recipientButtonNode.setAttributedTitle(input.recipientLabel, for: .normal)
        recipientButtonNode.titleNode.maximumNumberOfLines = 1
        recipientButtonNode.titleNode.truncationMode = .byTruncatingTail
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

    // MARK: - Callbacks
    @objc private func onReplyNodeTap() {
        onReplyTap?(self)
    }

    @objc private func onMenuNodeTap() {
        onMenuTap?(self)
    }

    @objc private func onRecipientsNodeTap() {
        onRecipientsTap?(self)
    }

    // MARK: - Layout
    private var contentSpec: ASStackLayoutSpec {
        switch nodeState {
        case .collapsed:
            return ASStackLayoutSpec(
                direction: .horizontal,
                spacing: 4,
                justifyContent: .spaceBetween,
                alignItems: .start,
                children: [infoSpec, expandNode]
            )
        case .expanded, .expandedWithRecipients:
            let children = nodeState == .expanded ? [headerSpec, encryptionInfoSpec] : [headerSpec, recipientsSpec, encryptionInfoSpec]
            return ASStackLayoutSpec(
                direction: .vertical,
                spacing: 8,
                justifyContent: .spaceBetween,
                alignItems: .stretch,
                children: children
            )
        }
    }

    public override func layoutSpecThatFits(_: ASSizeRange) -> ASLayoutSpec {
        replyNode.style.preferredSize = CGSize(width: 44, height: 44)
        menuNode.style.preferredSize = CGSize(width: 36, height: 44)
        expandNode.style.preferredSize = CGSize(width: 36, height: 44)

        return ASInsetLayoutSpec(
            insets: input.nodeInsets,
            child: contentSpec
        )
    }
}
