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

    private lazy var webViewNode: CustomWebViewNode = {
        let node = CustomWebViewNode()
        node.setAccessibilityIdentifier(accessibilityIdentifier: "aid-message-\(input.index)")
        node.setHtml("""
            <header>
                <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, minimum-scale=1.0, user-scalable=no">
            </header>
            \(input.message ?? "")
        """)
        node.style.flexGrow = 1.0
        return node
    }()

    public init(input: ThreadDetailWebNode.Input) {
        self.input = input

        super.init()
        addLeftBorder(width: .threadLeftBorderWidth, color: UIColor(hex: "777777"))
    }

    override public func layoutSpecThatFits(_: ASSizeRange) -> ASLayoutSpec {
        let specChild: ASLayoutElement

        specChild = webViewNode

        return ASInsetLayoutSpec(
            insets: .threadMessageInsets,
            child: specChild
        )
    }
}
