//
//  TextSubjectNode.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 06.11.2019.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import AsyncDisplayKit
import WebKit

public final class MessageTextSubjectNode: CellNode {
    public struct Input {
        let message: String?
        let quote: NSAttributedString?
        let index: Int
        let isEncrypted: Bool

        public init(message: String?, quote: NSAttributedString?, index: Int, isEncrypted: Bool) {
            self.message = message
            self.quote = quote
            self.index = index
            self.isEncrypted = isEncrypted
        }
    }

    private let input: MessageTextSubjectNode.Input

    private let messageNode = ASDisplayNode()
    private let quoteNode = ASEditableTextNode()

    private var shouldShowQuote = false

    private lazy var toggleQuoteButtonNode: ASButtonNode = {
        let configuration = UIImage.SymbolConfiguration(pointSize: 16, weight: .ultraLight)
        let image = UIImage(systemName: "ellipsis", withConfiguration: configuration)
        let button = ASButtonNode()
        button.cornerRadius = 4
        button.borderColor = UIColor.main.cgColor
        button.borderWidth = 1
        button.accessibilityIdentifier = "aid-message-\(input.index)-quote-toggle"
        button.setImage(image, for: .normal)
        button.contentEdgeInsets = .side(4)
        button.imageNode.imageModificationBlock = ASImageNodeTintColorModificationBlock(.main)
        button.addTarget(self, action: #selector(onToggleQuoteButtonTap), forControlEvents: .touchUpInside)
        return button
    }()

    public init(input: MessageTextSubjectNode.Input) {
        self.input = input

        super.init()

        DispatchQueue.main.async {
            let webView = WKWebView(frame: CGRect(x: 0, y: 0, width: 300, height: 300))
            webView.loadHTMLString(input.message ?? "", baseURL: nil)
            self.messageNode.view.addSubview(webView)
        }
        messageNode.accessibilityIdentifier = "aid-message-\(input.index)"

        if let quote = input.quote {
            setupTextNode(quoteNode, text: quote, accessibilityIdentifier: "aid-message-\(input.index)-quote")
        }
        addLeftBorder(width: .threadLeftBorderWidth, color: input.isEncrypted ? .main : UIColor(hex: "777777"))
    }

    private func setupTextNode(_ node: ASEditableTextNode, text: NSAttributedString?, accessibilityIdentifier: String) {
        node.attributedText = text
        node.isAccessibilityElement = true
        node.accessibilityIdentifier = accessibilityIdentifier
        node.accessibilityValue = text?.string

        DispatchQueue.main.async {
            node.textView.isSelectable = true
            node.textView.isEditable = false
            node.textView.dataDetectorTypes = .all
        }
    }

    override public func layoutSpecThatFits(_: ASSizeRange) -> ASLayoutSpec {
        messageNode.style.flexGrow = 1.0

        let specChild: ASLayoutElement

        if input.quote != nil {
            toggleQuoteButtonNode.style.spacingBefore = 8
            quoteNode.style.flexGrow = 1.0

            let stack = ASStackLayoutSpec.vertical()
            stack.alignItems = .start
            stack.spacing = 12

            if shouldShowQuote {
                stack.children = [messageNode, toggleQuoteButtonNode, quoteNode]
            } else {
                stack.children = [messageNode, toggleQuoteButtonNode]
            }

            specChild = stack
        } else {
            specChild = messageNode
        }

        return ASInsetLayoutSpec(
            insets: .threadMessageInsets,
            child: specChild
        )
    }

    @objc private func onToggleQuoteButtonTap() {
        shouldShowQuote.toggle()
        setNeedsLayout()
    }
}
