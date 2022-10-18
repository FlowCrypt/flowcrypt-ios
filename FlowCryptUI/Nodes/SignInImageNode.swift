//
//  SignInImageNode.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 23.10.2019.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import AsyncDisplayKit
import CoreServices
import UIKit

public final class SignInImageNode: CellNode {
    private let imageNode = ASImageNode()
    private let imageHeight: CGFloat

    public init(_ image: UIImage?, imageHeight: CGFloat) {
        self.imageHeight = imageHeight
        super.init()
        imageNode.image = image
        imageNode.contentMode = .scaleAspectFit
        addSubnode(imageNode)
        setNeedsLayout()
    }

    override public func layoutSpecThatFits(_: ASSizeRange) -> ASLayoutSpec {
        imageNode.style.preferredSize.height = imageHeight

        return ASInsetLayoutSpec(
            insets: .deviceSpecificInsets(
                top: UIDevice.isIphone ? 8 : 32,
                bottom: 0
            ),
            child: imageNode
        )
    }
}
