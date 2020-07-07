//
//  SetupButtonNode.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 29.10.2019.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import AsyncDisplayKit

public final class ButtonCellNode: CellNode {
    private var onTap: (() -> Void)?
    public lazy var button = ButtonNode { [weak self] in
        self?.onTap?()
    }

    private let insets: UIEdgeInsets
    private let buttonColor: UIColor?

    public var isButtonEnabled: Bool = true {
        didSet {
            button.isEnabled = isButtonEnabled
            let alpha: CGFloat = isButtonEnabled ? 1 : 0.5
            button.backgroundColor = (buttonColor ?? UIColor.main)
                .withAlphaComponent(alpha)
        }
    }

    public init(title: NSAttributedString, insets: UIEdgeInsets, color: UIColor? = nil, action: (() -> Void)?) {
        onTap = action
        self.insets = insets
        buttonColor = color
        super.init()
        button.cornerRadius = 5
        button.backgroundColor = color ?? .main
        button.style.preferredSize.height = 50
        button.setAttributedTitle(title, for: .normal)
    }

    public override func layoutSpecThatFits(_: ASSizeRange) -> ASLayoutSpec {
        ASInsetLayoutSpec(
            insets: insets,
            child: button
        )
    }
}
