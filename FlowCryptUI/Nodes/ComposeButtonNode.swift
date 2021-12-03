//
//  ComposeButtonNode.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 01.10.2019.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import AsyncDisplayKit

public final class ComposeButtonNode: ASButtonNode {
    private var onTap: (() -> Void)?

    public init(_ action: (() -> Void)?) {
        super.init()
        onTap = action
        backgroundColor = .main
        accessibilityIdentifier = "composeMessageButton"
        setTitle("+", with: UIFont.boldSystemFont(ofSize: 30), with: .white, for: .normal)
        addTarget(self, action: #selector(onButtonTap), forControlEvents: .touchUpInside)
    }

    @objc private func onButtonTap() {
        onTap?()
    }
}
