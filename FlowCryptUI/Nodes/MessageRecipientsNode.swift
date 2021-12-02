//
//  MessageRecipientsNode.swift
//  FlowCryptUI
//
//  Created by Roma Sosnovsky on 30/11/21
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import AsyncDisplayKit

public final class MessageRecipientsNode: ASDisplayNode {
    public struct Input {
        public let recipients: [String]
        public let ccRecipients: [String]
        public let bccRecipients: [String]

        public init(recipients: [String],
                    ccRecipients: [String],
                    bccRecipients: [String]) {
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

        borderColor = UIColor.tertiaryLabel.cgColor
        borderWidth = 1
        cornerRadius = 6
    }

    private func recipientList(label: String, recipients: [String]) -> ASStackLayoutSpec? {
        guard recipients.isNotEmpty else { return nil }

        let labelNode = ASTextNode2()
        labelNode.attributedText = label.localizedCapitalized.attributed()
        labelNode.style.preferredSize = CGSize(width: 30, height: 20)

        let children: [ASDisplayNode] = recipients.compactMap { recipient in
            let node = ASTextNode2()
            let parts = recipient.components(separatedBy: " ")
            if parts.count > 1 {
                guard let email = parts.last else { return nil }

                let attributedEmail = email.attributed(.regular(15), color: .secondaryLabel)
                let name = recipient
                    .replacingOccurrences(of: email, with: "")
                    .attributed(.regular(15), color: .label)
                let text = name.mutable()
                text.append(attributedEmail)
                node.attributedText = text
            } else {
                node.attributedText = recipient.attributed(.regular(15), color: .secondaryLabel)
            }

            return node
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

    public override func layoutSpecThatFits(_: ASSizeRange) -> ASLayoutSpec {
        let recipientsNodes: [ASStackLayoutSpec] = RecipientType.allCases.compactMap { type in
            let recipients: [String]
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
