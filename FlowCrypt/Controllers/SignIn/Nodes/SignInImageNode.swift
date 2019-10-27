//
//  SignInImageNode.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 23.10.2019.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import AsyncDisplayKit

final class SignInImageNode: ASCellNode {
    private let imageNode = ASImageNode()
    private var imageHeight: CGFloat = .zero

    init(_ image: UIImage?, height: CGFloat?) {
        super.init()
        imageNode.image = image
        imageNode.contentMode = .scaleAspectFit
        addSubnode(imageNode)
        imageHeight = height ?? .zero
        setNeedsLayout()
        selectionStyle = .none
    }

    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        imageNode.style.preferredSize.height = imageHeight
        return ASInsetLayoutSpec(
            insets: UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20),
            child: imageNode
        )
    }
}
