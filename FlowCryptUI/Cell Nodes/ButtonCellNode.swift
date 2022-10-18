//
//  SetupButtonNode.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 29.10.2019.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import AsyncDisplayKit

public final class ButtonCellNode: CellNode {
    public struct Input {
        let title: NSAttributedString
        let insets: UIEdgeInsets
        let color: UIColor?

        public init(
            title: NSAttributedString,
            insets: UIEdgeInsets = .buttonInsets,
            color: UIColor? = nil
        ) {
            self.title = title
            self.insets = insets
            self.color = color
        }
    }

    private var onTap: (() -> Void)?
    public lazy var button = ButtonNode { [weak self] in
        self?.onTap?()
    }

    private let insets: UIEdgeInsets
    private let buttonColor: UIColor?

    public var isButtonEnabled = true {
        didSet {
            button.isEnabled = isButtonEnabled
            let alpha: CGFloat = isButtonEnabled ? 1 : 0.5
            button.backgroundColor = (buttonColor ?? UIColor.main)
                .withAlphaComponent(alpha)
        }
    }

    public init(input: Input, action: (() -> Void)?) {
        onTap = action
        self.insets = input.insets
        buttonColor = input.color
        super.init()
        button.cornerRadius = 8
        button.backgroundColor = input.color ?? .main
        button.style.preferredSize.height = 50
        button.setAttributedTitle(input.title, for: .normal)
    }

    override public func layoutSpecThatFits(_: ASSizeRange) -> ASLayoutSpec {
        ASInsetLayoutSpec(
            insets: insets,
            child: button
        )
    }
}
