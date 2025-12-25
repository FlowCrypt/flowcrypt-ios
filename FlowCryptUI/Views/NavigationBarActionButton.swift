//
//  NavigationBarActionButton.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 8/23/19.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import UIKit

public final class NavigationBarActionButton: UIBarButtonItem {
    private enum Constants {
        static let buttonSize = CGSize(width: 44, height: 44)
    }

    private var onAction: (() -> Void)?

    public convenience init(imageSystemName: String, action: (() -> Void)?, accessibilityIdentifier: String? = nil) {
        self.init(image: UIImage(systemName: imageSystemName), style: .plain, target: nil, action: nil)
        self.target = self
        self.action = #selector(tap)
        self.accessibilityIdentifier = accessibilityIdentifier
        self.onAction = action
    }

    @objc private func tap() {
        onAction?()
    }
}
