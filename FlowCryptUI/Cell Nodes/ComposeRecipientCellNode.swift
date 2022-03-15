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
        public let recipients: String

        public init(
            recipients: String
        ) {
            self.recipients = recipients
        }
    }

    private var tapAction: (() -> Void)?
    private let recipientNode = ASTextNode2()

    public init(input: Input, tapAction: (() -> Void)? = nil) {
        super.init()
        recipientNode.attributedText = input.recipients.attributed(.regular(17), color: .gray, alignment: .left)
        self.tapAction = tapAction
        recipientNode.addTarget(self, action: #selector(onTextNodeTap), forControlEvents: .touchUpInside)
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
