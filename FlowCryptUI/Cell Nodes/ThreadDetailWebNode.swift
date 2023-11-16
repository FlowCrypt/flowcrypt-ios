//
//  ThreadDetailWebNode.swift
//  FlowCryptUI
//
//  Created by Ioan Moldoan on 11/16/23
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import AsyncDisplayKit

public final class ThreadDetailWebNode: CellNode {
    public struct Input {
        let message: String?
        let index: Int

        public init(message: String?, index: Int) {
            self.message = message
            self.index = index
        }
    }

    private let input: ThreadDetailWebNode.Input

    private let webViewNode = CustomWebViewNode()

    public init(input: ThreadDetailWebNode.Input) {
        self.input = input

        super.init()
        addLeftBorder(width: .threadLeftBorderWidth, color: UIColor(hex: "777777"))
    }

    override public func layoutSpecThatFits(_: ASSizeRange) -> ASLayoutSpec {
        webViewNode.style.flexGrow = 1.0

        let specChild: ASLayoutElement

        specChild = webViewNode

        return ASInsetLayoutSpec(
            insets: .threadMessageInsets,
            child: specChild
        )
    }
}
