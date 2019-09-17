//
//  NavigationBarActionButton.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 8/23/19.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import UIKit

final class NavigationBarActionButton: UIBarButtonItem {

    private enum Constants {
        static let buttonSize = CGSize(width: 44, height: 44)
    }

    private var onAction: (() -> Void)?

    convenience init(_ image: UIImage?, action: (() -> Void)?) {
        self.init()
        onAction = action
        customView = LeftAlignedIconButton(type: .system).with {
            $0.setImage(image, for: .normal)
            $0.frame.size = Constants.buttonSize
            $0.addTarget(self, action: #selector(tap), for: .touchUpInside)
        }
    }

    @objc private func tap() {
        onAction?()
    }
}

fileprivate final class LeftAlignedIconButton: UIButton {
    override func layoutSubviews() {
        super.layoutSubviews()
        contentHorizontalAlignment = .left
        let availableSpace = bounds.inset(by: contentEdgeInsets)
        let availableWidth = availableSpace.width - imageEdgeInsets.right - (imageView?.frame.width ?? 0) - (titleLabel?.frame.width ?? 0)
        titleEdgeInsets = UIEdgeInsets(top: 0, left: availableWidth / 2, bottom: 0, right: 0)
    }
}
