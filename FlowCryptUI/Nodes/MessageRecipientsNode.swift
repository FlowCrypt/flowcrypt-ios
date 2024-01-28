//
//  MessageRecipientsNode.swift
//  FlowCryptUI
//
//  Created by Roma Sosnovsky on 30/11/21
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import AsyncDisplayKit

public typealias MessageRecipient = (name: String?, email: String)

public final class MessageRecipientsNode: ASDisplayNode {
    public struct Input {
        let recipients: [MessageRecipient]
        let ccRecipients: [MessageRecipient]
        let bccRecipients: [MessageRecipient]

        public init(
            recipients: [MessageRecipient],
            ccRecipients: [MessageRecipient],
            bccRecipients: [MessageRecipient]
        ) {
            self.recipients = recipients
            self.ccRecipients = ccRecipients
            self.bccRecipients = bccRecipients
        }
    }

    private let input: MessageRecipientsNode.Input

    private enum RecipientType: String, CaseIterable {
        case to, cc, bcc
    }

    public init(input: MessageRecipientsNode.Input) {
        self.input = input

        super.init()

        automaticallyManagesSubnodes = true
        setupBorder()
    }

    private func setupBorder() {
        borderColor = UIColor.tertiaryLabel.cgColor
        borderWidth = 1
        cornerRadius = 6
    }

    private func recipientList(label: String, recipients: [MessageRecipient]) -> ASStackLayoutSpec? {
        guard recipients.isNotEmpty else { return nil }

        let labelNode = ASTextNode2()
        labelNode.attributedText = label.localizedCapitalized.attributed()
        labelNode.style.preferredSize = CGSize(width: 30, height: 20)

        let children = recipients.enumerated().map { index, recipient in
            return recipientNode(for: recipient, identifier: "aid-\(label)-\(index)-label")
        }
        let recipientsList = ASStackLayoutSpec(
            direction: .vertical,
            spacing: 4,
            justifyContent: .start,
            alignItems: .start,
            children: children
        )
        recipientsList.style.flexShrink = 1

        return ASStackLayoutSpec(
            direction: .horizontal,
            spacing: 4,
            justifyContent: .start,
            alignItems: .start,
            children: [labelNode, recipientsList]
        )
    }

    private func recipientNode(for recipient: MessageRecipient, identifier: String) -> ASTextNode2 {
        let style: NSAttributedString.Style = .regular(15)
        let nameString = recipient.name?.attributed(style, color: .label)
        let emailString = recipient.email.attributed(style, color: .secondaryLabel)
        let separator = " ".attributed(style)

        let node = ASTextNode2()
        node.accessibilityIdentifier = identifier
        node.attributedText = [nameString, emailString]
            .compactMap { $0 }
            .reduce(NSMutableAttributedString()) {
                if !$0.string.isEmpty { $0.append(separator) }
                $0.append($1)
                return $0
            }

        return node
    }

    override public func layoutSpecThatFits(_: ASSizeRange) -> ASLayoutSpec {
        let recipientsNodes: [ASStackLayoutSpec] = RecipientType.allCases.compactMap { type in
            let recipients: [MessageRecipient]
            switch type {
            case .to:
                recipients = input.recipients
            case .cc:
                recipients = input.ccRecipients
            case .bcc:
                recipients = input.bccRecipients
            }
            return recipientList(label: type.rawValue, recipients: recipients)
        }

        return ASInsetLayoutSpec(
            insets: UIEdgeInsets(top: 6, left: 6, bottom: 6, right: 6),
            child: ASStackLayoutSpec(
                direction: .vertical,
                spacing: 6,
                justifyContent: .spaceBetween,
                alignItems: .start,
                children: recipientsNodes
            )
        )
    }
}
