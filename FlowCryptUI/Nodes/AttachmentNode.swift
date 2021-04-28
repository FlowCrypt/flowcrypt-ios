//
//  AttachmentNode.swift
//  FlowCryptUI
//
//  Created by QSD BiH on 16. 4. 2021..
//  Copyright © 2021 FlowCrypt Limited. All rights reserved.
//

import AsyncDisplayKit

public struct Attachment {
    var name, size: NSAttributedString
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

    public init(input: [Input]) {
        super.init()
        input.forEach { input in
            attachmentNodes.append(
                AttachmentNode(
                    input: AttachmentNode.Input(name: input.name, size: input.size)
                )
            )
        }
    }

    public override func layoutSpecThatFits(_: ASSizeRange) -> ASLayoutSpec {
        return ASInsetLayoutSpec(
            insets: UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0),
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

    public init(input: Input) {
        super.init()
        self.borderWidth = 0.5
        self.borderColor = UIColor(named: "red")?.cgColor

        imageNode.image = UIImage(named: "paperclip")
        buttonNode.setImage(UIImage(named: "paperclip"), for: .normal)
        titleNode.attributedText = NSAttributedString.text(from: input.name, style: .medium(16))
        subtitleNode.attributedText = NSAttributedString.text(from: input.size, style: .medium(12))
    }

    public override func layoutSpecThatFits(_: ASSizeRange) -> ASLayoutSpec {
        let verticalStack = ASStackLayoutSpec.vertical()
        verticalStack.spacing = 6
        verticalStack.style.flexShrink = 1.0
        verticalStack.style.flexGrow = 1.0
        separatorNode.style.flexGrow = 1.0
        separatorNode.style.preferredSize.height = 1.0

        verticalStack.children = [titleNode, subtitleNode]

        let finalSpec = ASStackLayoutSpec(
            direction: .horizontal,
            spacing: 8,
            justifyContent: .start,
            alignItems: .center,
            children: [imageNode, verticalStack, separatorNode, buttonNode]
        )

        return ASInsetLayoutSpec(
            insets: UIEdgeInsets(top: 10, left: 16, bottom: 10, right: 16),
            child: finalSpec
        )
    }
}
