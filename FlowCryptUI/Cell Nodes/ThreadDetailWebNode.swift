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
        let quote: String?
        let index: Int
        let isEncrypted: Bool

        public init(message: String?, quote: String?, index: Int, isEncrypted: Bool) {
            self.message = message
            self.quote = quote
            self.index = index
            self.isEncrypted = isEncrypted
        }
    }

    private let input: ThreadDetailWebNode.Input

    private lazy var messageNode: CustomWebViewNode = {
        let node = CustomWebViewNode()
        node.setAccessibilityIdentifier(accessibilityIdentifier: "aid-message-\(input.index)")
        node.setHtml(getFormattedHtml(html: input.message))
        node.style.flexGrow = 1.0
        return node
    }()

    private lazy var quoteNode: CustomWebViewNode = {
        let node = CustomWebViewNode()
        node.style.flexGrow = 1.0
        return node
    }()

    private var shouldShowQuote = false

    private lazy var toggleQuoteButtonNode: ToggleQuoteButtonNode = {
        let node = ToggleQuoteButtonNode(index: input.index) { [weak self] in
            self?.onToggleQuoteButtonTap()
        }
        return node
    }()

    public init(input: ThreadDetailWebNode.Input) {
        self.input = input

        super.init()
        addLeftBorder(width: .threadLeftBorderWidth, color: input.isEncrypted ? .main : .plainTextBorder)
    }

    private func getFormattedHtml(html: String?) -> String {
        // swiftlint:disable line_length
        return """
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
            \(html ?? "")
        """
        // swiftlint:enable line_length
    }

    override public func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        var nodes: [ASLayoutElement] = [messageNode]
        messageNode.style.preferredSize.width = constrainedSize.max.width
        quoteNode.style.preferredSize.width = constrainedSize.max.width
        if input.quote != nil {
            nodes.append(toggleQuoteButtonNode)
            if shouldShowQuote {
                nodes.append(quoteNode)
            }
        }
        let contentSpec = ASStackLayoutSpec(
            direction: .vertical,
            spacing: 12,
            justifyContent: .start,
            alignItems: .start,
            children: nodes
        )

        return ASInsetLayoutSpec(
            insets: .threadMessageInsets,
            child: contentSpec
        )
    }

    private func onToggleQuoteButtonTap() {
        shouldShowQuote.toggle()
        if let quote = input.quote, shouldShowQuote {
            // Set quote node html here because wkwebview can't get correct height when node is hidden
            quoteNode.setHtml(getFormattedHtml(html: quote))
        }
        setNeedsLayout()
    }
}
