//
//  AttachmentNode.swift
//  FlowCryptUI
//
//  Created by QSD BiH on 16. 4. 2021..
//  Copyright © 2021 FlowCrypt Limited. All rights reserved.
//

import AsyncDisplayKit

<<<<<<< HEAD
public final class AttachmentNode: CellNode {
    public struct Input {
        let name: NSAttributedString
        let size: NSAttributedString

        public init(name: NSAttributedString, size: NSAttributedString) {
=======
public struct Attachment {
    var name, size: String

    public init(
        name: String,
        size: Int
    ) {
        self.name = name
        self.size = ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file)
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
>>>>>>> 9632392b97ddd577aa5838c2f24ec75ad4b046e1
            self.name = name
            self.size = size
        }
    }
<<<<<<< HEAD
    
=======

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

>>>>>>> 9632392b97ddd577aa5838c2f24ec75ad4b046e1
    private let titleNode = ASTextNode()
    private let subtitleNode = ASTextNode2()
    private let imageNode = ASImageNode()
    private let buttonNode = ASButtonNode()

    private var onTap: (() -> Void)?

<<<<<<< HEAD
    init(input: Input, onTap: (() -> Void)?) {
=======
    public init(input: Input, onTap: (() -> Void)?) {
>>>>>>> 9632392b97ddd577aa5838c2f24ec75ad4b046e1
        super.init()
        self.onTap = onTap

        self.borderWidth = 1.0
        self.cornerRadius = 8.0
        self.borderColor = UIColor.lightGray.cgColor

        imageNode.tintColor = .gray
        buttonNode.tintColor = .gray

        imageNode.image = UIImage(named: "paperclip")?.tinted(.gray)
        buttonNode.setImage(UIImage(named: "download")?.tinted(.gray), for: .normal)
        buttonNode.addTarget(self, action: #selector(tapHandle), forControlEvents: .touchUpInside)
<<<<<<< HEAD
        titleNode.attributedText = input.name
        subtitleNode.attributedText = input.size
    }
    
=======
        titleNode.attributedText = NSAttributedString.text(from: input.name, style: .regular(18), color: .gray, alignment: .left)
        subtitleNode.attributedText = NSAttributedString.text(from: input.size, style: .medium(12), color: .gray, alignment: .left)
    }

>>>>>>> 9632392b97ddd577aa5838c2f24ec75ad4b046e1
    public override func layoutSpecThatFits(_: ASSizeRange) -> ASLayoutSpec {
        let verticalStack = ASStackLayoutSpec.vertical()
        verticalStack.spacing = 3
        verticalStack.style.flexShrink = 1.0
        verticalStack.style.flexGrow = 1.0

        verticalStack.children = [titleNode, subtitleNode]
<<<<<<< HEAD
        
=======

>>>>>>> 9632392b97ddd577aa5838c2f24ec75ad4b046e1
        let finalSpec = ASStackLayoutSpec(
            direction: .horizontal,
            spacing: 10,
            justifyContent: .start,
            alignItems: .center,
            children: [imageNode, verticalStack, buttonNode]
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
