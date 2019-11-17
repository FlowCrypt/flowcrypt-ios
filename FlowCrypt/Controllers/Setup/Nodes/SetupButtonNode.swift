//
//  SetupButtonNode.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 29.10.2019.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import AsyncDisplayKit

final class SetupButtonNode: CellNode {
    private var onTap: (() -> Void)?
    private lazy var button = ButtonNode() { [weak self] in
        self?.onTap?()
    }
    private let insets: UIEdgeInsets
    private let buttonColor: UIColor?

    var isButtonEnabled: Bool = true {
        didSet {
            button.isEnabled = isButtonEnabled
            let alpha: CGFloat = isButtonEnabled ? 1 : 0.5
            button.backgroundColor = (self.buttonColor ?? UIColor.main)
                .withAlphaComponent(alpha)
        }
    }


    init(title: NSAttributedString, insets: UIEdgeInsets, color: UIColor? = nil, action: (() -> Void)?) {
        self.onTap = action
        self.insets = insets
        self.buttonColor = color
        super.init() 
        button.cornerRadius = 5
        button.backgroundColor = color ?? .main
        button.style.preferredSize.height = 50
        button.setAttributedTitle(title, for: .normal)
    }

    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        ASInsetLayoutSpec(
            insets: insets,
            child: button
        )
    }
}
