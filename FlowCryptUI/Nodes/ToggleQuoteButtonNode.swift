//
//  ToggleQuoteButtonNode.swift
//  FlowCryptUI
//
//  Created by Ioan Moldovan on 11/28/23
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import AsyncDisplayKit
public final class ToggleQuoteButtonNode: ASButtonNode {
    private let onTap: (() -> Void)?

    public init(index: Int, onTap: (() -> Void)? = nil) {
        self.onTap = onTap

        super.init()

        let configuration = UIImage.SymbolConfiguration(pointSize: 16, weight: .ultraLight)
        let image = UIImage(systemName: "ellipsis", withConfiguration: configuration)
        cornerRadius = 4
        borderColor = UIColor.main.cgColor
        borderWidth = 1
        accessibilityIdentifier = "aid-message-\(index)-quote-toggle"
        setImage(image, for: .normal)
        contentEdgeInsets = .side(4)
        imageNode.imageModificationBlock = ASImageNodeTintColorModificationBlock(.main)
        addTarget(self, action: #selector(onToggleQuoteButtonTap), forControlEvents: .touchUpInside)
    }

    @objc private func onToggleQuoteButtonTap() {
        onTap?()
    }
}
