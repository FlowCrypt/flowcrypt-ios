//
//  SigninButtonNode.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 23.10.2019.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import AsyncDisplayKit

public final class SigninButtonNode: CellNode {
    public struct Input {
        let title: NSAttributedString
        let image: UIImage?

        public init(
            title: NSAttributedString,
            image: UIImage?
        ) {
            self.title = title
            self.image = image
        }
    }

    public let button = ASButtonNode()
    private var onTap: (() -> Void)?

    public init(input: Input, onTap: (() -> Void)?) {
        super.init()
        self.onTap = onTap
        automaticallyManagesSubnodes = true
        button.setAttributedTitle(input.title, for: .normal)
        button.setImage(input.image, for: .normal)
        button.addTarget(self, action: #selector(tapHandle), forControlEvents: .touchUpInside)

        button.style.preferredSize.height = 50
        button.cornerRadius = 5
        button.borderColor = UIColor.lightGray.cgColor
        button.borderWidth = 1.0
        button.accessibilityIdentifier = input.title.string
        selectionStyle = .none
    }

    @objc private func tapHandle() {
        onTap?()
    }

    override public func layoutSpecThatFits(_: ASSizeRange) -> ASLayoutSpec {
        ASInsetLayoutSpec(
            insets: .deviceSpecificInsets(
                top: 16,
                bottom: 16
            ),
            child: button
        )
    }
}
