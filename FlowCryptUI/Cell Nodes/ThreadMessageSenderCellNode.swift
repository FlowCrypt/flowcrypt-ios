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
        public let signature: NSAttributedString?
        public let signatureColor: UIColor?
        public let signatureIcon: String?

        public let sender: NSAttributedString
        public let date: NSAttributedString?
        public let isExpanded: Bool
        public let buttonColor: UIColor

        public init(signature: NSAttributedString,
                    signatureColor: UIColor?,
                    signatureIcon: String?,
                    sender: NSAttributedString,
                    date: NSAttributedString,
                    isExpanded: Bool,
                    buttonColor: UIColor) {
            self.signature = signature
            self.signatureColor = signatureColor
            self.signatureIcon = signatureIcon
            self.sender = sender
            self.date = date
            self.isExpanded = isExpanded
            self.buttonColor = buttonColor
        }

        var replyImage: UIImage? {
            return createButtonImage(systemName: "arrowshape.turn.up.left")
        }
        var expandImage: UIImage? {
            let systemName = isExpanded ? "chevron.up" : "chevron.down"
            return createButtonImage(systemName: systemName)
        }

        private func createButtonImage(systemName: String, pointSize: CGFloat = 18) -> UIImage? {
            let configuration = UIImage.SymbolConfiguration(pointSize: pointSize)
            return UIImage(systemName: systemName, withConfiguration: configuration)
        }
    }

    private lazy var signatureNode: ThreadMessageSignatureNode = {
        let input = ThreadMessageSignatureNode.Input(
            signature: input.signature,
            color: input.signatureColor,
            icon: input.signatureIcon
        )
        return ThreadMessageSignatureNode(input: input)
    }()

    private let senderNode = ASTextNode2()
    private let dateNode = ASTextNode2()

    public private(set) var replyNode = ASButtonNode()
    public private(set) var expandNode = ASImageNode()

    private let input: ThreadMessageSenderCellNode.Input
    private var onReplyTap: ((ThreadMessageSenderCellNode) -> Void)?

    public init(input: ThreadMessageSenderCellNode.Input,
                onReplyTap: ((ThreadMessageSenderCellNode) -> Void)?) {
        self.input = input
        self.onReplyTap = onReplyTap
        super.init()
        automaticallyManagesSubnodes = true

        senderNode.attributedText = input.sender
        dateNode.attributedText = input.date

        setupReplyNode()
        setupExpandNode()
    }

    private func setupReplyNode() {
        replyNode.setImage(input.replyImage, for: .normal)
        replyNode.imageNode.imageModificationBlock = ASImageNodeTintColorModificationBlock(input.buttonColor)
        replyNode.contentMode = .center
        replyNode.alpha = input.isExpanded ? 1 : 0
        replyNode.addTarget(self, action: #selector(onReplyNodeTap), forControlEvents: .touchUpInside)
    }

    private func setupExpandNode() {
        expandNode.image = input.expandImage
        expandNode.imageModificationBlock = ASImageNodeTintColorModificationBlock(input.buttonColor)
        expandNode.contentMode = .right
    }

    @objc private func onReplyNodeTap() {
        onReplyTap?(self)
    }

    public override func layoutSpecThatFits(_: ASSizeRange) -> ASLayoutSpec {
        replyNode.style.preferredSize = CGSize(width: 44, height: 44)
        expandNode.style.preferredSize = CGSize(width: 18, height: 44)

        let spacer = ASLayoutSpec()
        spacer.style.flexGrow = 1.0

        let infoNode = ASStackLayoutSpec(
            direction: .vertical,
            spacing: 4,
            justifyContent: .spaceBetween,
            alignItems: .start,
            children: [senderNode, dateNode]
        )

        let senderSpec = ASStackLayoutSpec(
            direction: .horizontal,
            spacing: 4,
            justifyContent: .spaceBetween,
            alignItems: .start,
            children: [infoNode, spacer, replyNode, expandNode]
        )

        let contentSpec = ASStackLayoutSpec(
            direction: .vertical,
            spacing: 4,
            justifyContent: .spaceBetween,
            alignItems: .start,
            children: [signatureNode, senderSpec]
        )

        return ASInsetLayoutSpec(
            insets: UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 12),
            child: contentSpec
        )
    }
}

private final class ThreadMessageSignatureNode: ASDisplayNode {
    public struct Input {
        public let signature: NSAttributedString?
        public let color: UIColor?
        public let icon: String?

        public init(signature: NSAttributedString?,
                    color: UIColor?,
                    icon: String?) {
            self.signature = signature
            self.color = color
            self.icon = icon
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

    private let signatureNode = ASTextNode2()
    private let input: ThreadMessageSignatureNode.Input

    init(input: ThreadMessageSignatureNode.Input) {
        self.input = input
        super.init()

        automaticallyManagesSubnodes = true

        signatureNode.attributedText = input.signature
        backgroundColor = input.color
        cornerRadius = 4
    }

    public override func layoutSpecThatFits(_: ASSizeRange) -> ASLayoutSpec {
        let contentSpec = ASStackLayoutSpec(
            direction: .horizontal,
            spacing: 2,
            justifyContent: .spaceBetween,
            alignItems: .center,
            children: [iconNode, signatureNode].compactMap { $0 }
        )

        return ASInsetLayoutSpec(
            insets: UIEdgeInsets(top: 2, left: 4, bottom: 2, right: 4),
            child: contentSpec
        )
    }
}
