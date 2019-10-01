//
//  ComposeButtonNode.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 01.10.2019.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import AsyncDisplayKit

 final class ComposeButtonNode: ASButtonNode {
    private var onTap: (() -> Void)?

     init(_ action: (() -> Void)?) {
        super.init()
        onTap = action
        backgroundColor = .main
        setTitle("+", with: UIFont.boldSystemFont(ofSize: 30), with: .white, for: .normal)
        addTarget(self, action: #selector(onButtonTap), forControlEvents: .touchUpInside)
    }

     @objc private func onButtonTap() {
        onTap?()
    }
}
