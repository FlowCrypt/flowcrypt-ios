//
//  AddButtonNode.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 01.10.2019.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import AsyncDisplayKit

public final class AddButtonNode: ASButtonNode {
    private var onTap: (() -> Void)?

    public init(_ action: (() -> Void)?) {
        super.init()
        onTap = action
        backgroundColor = .main
        accessibilityIdentifier = "aid-compose-message-button"
        setTitle("+", with: .boldSystemFont(ofSize: 30), with: .white, for: .normal)
        addTarget(self, action: #selector(onButtonTap), forControlEvents: .touchUpInside)
        frame.size = CGSize(width: .addButtonSize, height: .addButtonSize)
        cornerRadius = .addButtonSize / 2
    }

    @objc private func onButtonTap() {
        onTap?()
    }
}
