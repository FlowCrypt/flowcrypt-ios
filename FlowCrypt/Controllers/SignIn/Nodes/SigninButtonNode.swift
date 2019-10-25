//
//  SigninButtonNode.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 23.10.2019.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import AsyncDisplayKit

final class SigninButtonNode: ASCellNode {
    private let button = ASButtonNode()
    private var onTap: (() -> ())?
    
    init(title: NSAttributedString, image: UIImage?, onTap: (() -> Void)?) {
        super.init()
        self.onTap = onTap
        automaticallyManagesSubnodes = true
        button.setAttributedTitle(title, for: .normal)
        button.setImage(image, for: .normal)
        button.addTarget(self, action: #selector(tapHandle), forControlEvents: .touchUpInside)

        button.style.preferredSize.height = 50
        button.cornerRadius = 5
        button.borderColor = UIColor.lightGray.cgColor
        button.borderWidth = 1.0
        selectionStyle = .none
    }

    convenience init(_ buttonType: SignInType, onTap: (() -> Void)?) {
        self.init(title: buttonType.attributedTitle, image: buttonType.image, onTap: onTap)
        button.accessibilityLabel = buttonType.rawValue
    }

    @objc private func tapHandle() {
        onTap?()
    }

    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        return ASInsetLayoutSpec(
            insets: UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16),
            child: button
        )
    }
}
