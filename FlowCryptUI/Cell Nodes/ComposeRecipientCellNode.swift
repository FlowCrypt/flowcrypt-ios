//
//  ComposeRecipientCellNode.swift
//  FlowCrypt
//
//  Created by Ioan Moldovan on 03.15.2022.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import AsyncDisplayKit
import UIKit

public final class ComposeRecipientCellNode: CellNode {
    public struct Input {
        public let recipients: [RecipientEmailsCellNode.Input]

        public init(
            recipients: [RecipientEmailsCellNode.Input]
        ) {
            self.recipients = recipients
        }
    }

    private var tapAction: (() -> Void)?
    private let recipientNode = ASTextNode2()

    public init(
        input: Input,
        accessibilityIdentifier: String,
        titleNodeBackgroundColorSelected: UIColor,
        tapAction: (() -> Void)? = nil
    ) {
        super.init()
        self.tapAction = tapAction
        recipientNode.addTarget(self, action: #selector(onTextNodeTap), forControlEvents: .touchUpInside)

        recipientNode.accessibilityIdentifier = accessibilityIdentifier
        recipientNode.attributedText = input.recipients.map { (recipient) -> NSAttributedString in
            // Use black text color for gray bubbles
            let textColor = recipient.state.backgroundColor == titleNodeBackgroundColorSelected ? .black : recipient.state.backgroundColor
            return recipient.email.string.attributed(.regular(17), color: textColor, alignment: .left)
        }.reduce(NSMutableAttributedString()) { (r, e) in
            if r.length > 0 {
                r.append(NSAttributedString(", "))
            }
            r.append(e)
            return r
        }
    }

    public override func layoutSpecThatFits(_: ASSizeRange) -> ASLayoutSpec {
        return ASInsetLayoutSpec(
            insets: .deviceSpecificTextInsets(top: 8, bottom: 8),
            child: recipientNode
        )
    }

    @objc private func onTextNodeTap() {
        tapAction?()
    }
}
