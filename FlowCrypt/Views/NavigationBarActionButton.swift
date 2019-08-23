//
//  NavigationBarActionButton.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 8/23/19.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import UIKit

final class NavigationBarActionButton: UIBarButtonItem {

    private var onAction: (() -> Void)?

    convenience init(_ image: UIImage?, block: (() -> Void)?) {
        self.init()
        onAction = block
        customView = UIButton(type: .system).with {
            $0.setImage(image, for: .normal)
            $0.imageEdgeInsets = Constants.leftUiBarButtonItemImageInsets
            $0.frame = Constants.uiBarButtonItemFrame
            $0.addTarget(self, action: #selector(tap), for: .touchUpInside)
        }
    }

    @objc private func tap() {
        onAction?()
    }
}
