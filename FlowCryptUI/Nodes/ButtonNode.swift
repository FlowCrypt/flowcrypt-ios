//
//  ButtonNode.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 29.10.2019
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import AsyncDisplayKit

public final class ButtonNode: ASButtonNode {
    private var onTap: (() -> Void)?

    public init(_ action: (() -> Void)?) {
        onTap = action
        super.init()
        addTarget(self, action: #selector(handleTap), forControlEvents: .touchUpInside)
    }

    @objc private func handleTap() {
        onTap?()
    }
}
