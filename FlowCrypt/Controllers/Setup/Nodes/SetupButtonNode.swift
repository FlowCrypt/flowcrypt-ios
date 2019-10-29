//
//  SetupButtonNode.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 29.10.2019.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import AsyncDisplayKit

final class SetupButtonNode: ASCellNode {
    private var onTap: (() -> Void)?
    private lazy var button = ButtonNode() { [weak self] in
        self?.onTap?()
    }

    init(_ title: NSAttributedString, color: UIColor? = nil, action: (() -> Void)?) {
        self.onTap = action
        super.init()
        automaticallyManagesSubnodes = true
        selectionStyle = .none
        button.cornerRadius = 5
        button.backgroundColor = color ?? .main
        button.style.preferredSize.height = 50
        button.setAttributedTitle(title, for: .normal)
    }

    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        ASInsetLayoutSpec(
            insets: UIEdgeInsets(top: 8, left: 24, bottom: 8, right: 24),
            child: button
        )
    }
}
