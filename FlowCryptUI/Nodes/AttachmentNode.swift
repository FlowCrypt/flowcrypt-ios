//
//  AttachmentNode.swift
//  FlowCryptUI
//
//  Created by QSD BiH on 16. 4. 2021..
//  Copyright © 2021 FlowCrypt Limited. All rights reserved.
//

import AsyncDisplayKit

public final class AttachmentNode: CellNode {
    public struct Input {
        let name: NSAttributedString
        let size: NSAttributedString

        public init(name: NSAttributedString, size: NSAttributedString) {
            self.name = name
            self.size = size
        }
    }
    
    private let titleNode = ASTextNode()
    private let subtitleNode = ASTextNode2()
    private let imageNode = ASImageNode()
    private let buttonNode = ASButtonNode()

    private var onTap: (() -> Void)?

    init(input: Input, onTap: (() -> Void)?) {
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
        titleNode.attributedText = input.name
        subtitleNode.attributedText = input.size
    }
    
    public override func layoutSpecThatFits(_: ASSizeRange) -> ASLayoutSpec {
        let verticalStack = ASStackLayoutSpec.vertical()
        verticalStack.spacing = 3
        verticalStack.style.flexShrink = 1.0
        verticalStack.style.flexGrow = 1.0

        verticalStack.children = [titleNode, subtitleNode]
        
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
