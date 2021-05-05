//
//  AttachmentNode.swift
//  FlowCryptUI
//
//  Created by QSD BiH on 16. 4. 2021..
//  Copyright © 2021 FlowCrypt Limited. All rights reserved.
//

import AsyncDisplayKit

public struct Attachment {
    var name, size: String

    public init(
        name: String,
        size: String
    ) {
        self.name = name
        self.size = size
    }
}

public final class AttachmentsNode: CellNode {
    public struct Input {
        let name: String
        let size: String

        public init(
            name: String,
            size: String
        ) {
            self.name = name
            self.size = size
        }
    }

    private var attachmentNodes: [AttachmentNode] = []
    private var onTap: (() -> Void)?
    
    public init(attachments: [Attachment], onTap: (() -> Void)?) {
        super.init()
        self.onTap = onTap
        attachmentNodes = attachments.map { AttachmentNode(input: AttachmentNode.Input(name: $0.name, size: $0.size),
                                                           onTap: {
                                                            self.onTap?()
                                                           })
                                                        }
    }

    public override func layoutSpecThatFits(_: ASSizeRange) -> ASLayoutSpec {
        return ASInsetLayoutSpec(
            insets: UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8),
            child: ASStackLayoutSpec(
                direction: .vertical,
                spacing: 8,
                justifyContent: .start,
                alignItems: .stretch,
                children: attachmentNodes))
    }
}

public final class AttachmentNode: CellNode {
    public struct Input {
        var name, size: String
    }

    private let titleNode = ASTextNode()
    private let subtitleNode = ASTextNode2()
    private let imageNode = ASImageNode()
    private let buttonNode = ASButtonNode()
    private let separatorNode = ASDisplayNode()

    private var onTap: (() -> Void)?

    public init(input: Input, onTap: (() -> Void)?) {
        super.init()
        self.onTap = onTap

        self.borderWidth = 1.0
        self.cornerRadius = 8.0
        self.borderColor = UIColor.lightGray.cgColor

        imageNode.tintColor = .gray
        buttonNode.tintColor = .gray

        imageNode.image = UIImage(named: "paperclip")
        buttonNode.setImage(UIImage(named: "download"), for: .normal)
        buttonNode.addTarget(self, action: #selector(tapHandle), forControlEvents: .touchUpInside)
        titleNode.attributedText = NSAttributedString.text(from: input.name, style: .regular(18), color: .gray, alignment: .left)
        subtitleNode.attributedText = NSAttributedString.text(from: input.size, style: .medium(12), color: .gray, alignment: .left)
    }

    public override func layoutSpecThatFits(_: ASSizeRange) -> ASLayoutSpec {
        let verticalStack = ASStackLayoutSpec.vertical()
        verticalStack.spacing = 3
        verticalStack.style.flexShrink = 1.0
        verticalStack.style.flexGrow = 1.0
        separatorNode.style.flexGrow = 1.0
        separatorNode.style.preferredSize.height = 1.0

        verticalStack.children = [titleNode, subtitleNode]

        let finalSpec = ASStackLayoutSpec(
            direction: .horizontal,
            spacing: 10,
            justifyContent: .start,
            alignItems: .center,
            children: [imageNode, verticalStack, separatorNode, buttonNode]
        )

        return ASInsetLayoutSpec(
            insets: UIEdgeInsets(top: 10, left: 20, bottom: 10, right: 20),
            child: finalSpec
        )
    }

    @objc private func tapHandle() {
        onTap?()
    }
}
