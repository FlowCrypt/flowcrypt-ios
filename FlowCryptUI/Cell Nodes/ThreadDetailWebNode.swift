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
                <style>
                    * { font-family: -apple-system, "Helvetica Neue", sans-serif; }
                    :root { color-scheme: light dark; supported-color-schemes: light dark; }
                    @media (prefers-color-scheme: dark) {
                        :root {
                            background-color: #2D2C2E;
                            color: white;
                        }
                        a {
                            color: #1783FD;
                        }
                    }
                    html, body { padding: 0 !important; margin: 0 !important; }
                </style>
            </header>
            \(input.message ?? "")
        """)
        node.style.flexGrow = 1.0
        return node
    }()

    public init(input: ThreadDetailWebNode.Input) {
        self.input = input

        super.init()
        addLeftBorder(width: .threadLeftBorderWidth, color: .plainTextBorder)
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
