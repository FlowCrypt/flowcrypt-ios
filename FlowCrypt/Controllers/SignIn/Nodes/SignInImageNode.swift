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

    init(image: UIImage?) {
        super.init()
        imageNode.image = image
        automaticallyManagesSubnodes = true
    }

    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        return ASInsetLayoutSpec(
            insets: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0),
            child: ASCenterLayoutSpec(
                centeringOptions: .XY,
                sizingOptions: .minimumXY,
                child: imageNode
            )
        )
    }
}
