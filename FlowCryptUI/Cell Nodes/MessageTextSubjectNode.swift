//
//  TextSubjectNode.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 06.11.2019.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import AsyncDisplayKit

public final class MessageTextSubjectNode: CellNode {
    public struct Input {
        let message: NSAttributedString?
        let quote: NSAttributedString?
        let index: Int
        let isEncrypted: Bool

        public init(message: NSAttributedString?, quote: NSAttributedString?, index: Int, isEncrypted: Bool) {
            self.message = message
            self.quote = quote
            self.index = index
            self.isEncrypted = isEncrypted
        }
    }

    private let input: MessageTextSubjectNode.Input

    private let messageNode = ASEditableTextNode()
    private let quoteNode = ASEditableTextNode()

    private var shouldShowQuote = false

    private lazy var toggleQuoteButtonNode: ToggleQuoteButtonNode = {
        let node = ToggleQuoteButtonNode(index: input.index) { [weak self] in
            self?.onToggleQuoteButtonTap()
        }
        return node
    }()

    public init(input: MessageTextSubjectNode.Input) {
        self.input = input

        super.init()

        setupTextNode(messageNode, text: input.message, accessibilityIdentifier: "aid-message-\(input.index)")

        if let quote = input.quote {
            setupTextNode(quoteNode, text: quote, accessibilityIdentifier: "aid-message-\(input.index)-quote")
        }
        addLeftBorder(width: .threadLeftBorderWidth, color: input.isEncrypted ? .main : .plainTextBorder)
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

    private func onToggleQuoteButtonTap() {
        shouldShowQuote.toggle()
        setNeedsLayout()
    }
}
