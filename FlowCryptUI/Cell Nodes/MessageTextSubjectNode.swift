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

        public init(message: NSAttributedString?, quote: NSAttributedString?, index: Int) {
            self.message = message
            self.quote = quote
            self.index = index
        }
    }

    private let input: MessageTextSubjectNode.Input

    private let messageNode = ASEditableTextNode()
    private let quoteNode = ASEditableTextNode()

    private let insets = UIEdgeInsets.deviceSpecificTextInsets(top: 8, bottom: 8)

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

        setupTextNode(messageNode, text: input.message, accessibilityIdentifier: "aid-message-\(input.index)")

        if let quote = input.quote {
            setupTextNode(quoteNode, text: quote, accessibilityIdentifier: "aid-message-\(input.index)-quote")
        }
    }

    private func setupTextNode(_ node: ASEditableTextNode, text: NSAttributedString?, accessibilityIdentifier: String) {
        node.attributedText = text
        node.isAccessibilityElement = true
        node.accessibilityIdentifier = accessibilityIdentifier
        node.accessibilityValue = text?.string

        DispatchQueue.main.async {
            node.textView.isSelectable = true
            node.textView.isEditable = false
        }
    }

    override public func layoutSpecThatFits(_: ASSizeRange) -> ASLayoutSpec {
        messageNode.style.flexGrow = 1.0

        if input.quote != nil {
            toggleQuoteButtonNode.style.spacingBefore = 20
            quoteNode.style.flexGrow = 1.0

            let stack = ASStackLayoutSpec.vertical()
            stack.alignItems = .start

            if shouldShowQuote {
                stack.children = [messageNode, toggleQuoteButtonNode, quoteNode]
            } else {
                stack.children = [messageNode, toggleQuoteButtonNode]
            }

            return ASInsetLayoutSpec(
                insets: insets,
                child: stack
            )
        } else {
            return ASInsetLayoutSpec(
                insets: insets,
                child: messageNode
            )
        }
    }

    @objc private func onToggleQuoteButtonTap() {
        shouldShowQuote.toggle()
        setNeedsLayout()
    }
}
