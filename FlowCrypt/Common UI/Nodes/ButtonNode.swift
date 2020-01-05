//
//  ButtonNode.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 29.10.2019.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import AsyncDisplayKit

// TODO: - Refactor with this button
final class ButtonNode: ASButtonNode {
    private var onTap: (() -> Void)?

    init(_ action: (() -> Void)?) {
        self.onTap = action
        super.init()
        addTarget(self, action: #selector(handleTap), forControlEvents: .touchUpInside)
    }

    @objc private func handleTap() {
        onTap?()
    }
}
