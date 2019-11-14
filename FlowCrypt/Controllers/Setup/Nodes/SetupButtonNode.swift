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

    init(title: NSAttributedString, insets: UIEdgeInsets, color: UIColor? = nil, action: (() -> Void)?) {
        self.onTap = action
        self.insets = insets
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
