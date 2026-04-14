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
        self.init()
        onAction = action
        customView = UIButton(type: .system).with {
            $0.contentHorizontalAlignment = .left
            $0.setImage(UIImage(systemName: imageSystemName), for: .normal)
            $0.frame.size = Constants.buttonSize
            $0.addTarget(self, action: #selector(tap), for: .touchUpInside)
            $0.accessibilityIdentifier = accessibilityIdentifier
            $0.isAccessibilityElement = true
        }
    }

    @objc private func tap() {
        onAction?()
    }
}
