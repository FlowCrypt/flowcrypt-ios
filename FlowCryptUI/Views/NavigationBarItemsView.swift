//
//  NavigationBarItemsView.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 8/23/19.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import UIKit

public final class NavigationBarItemsView: UIBarButtonItem {
    private enum Constants {
        static let buttonSize = CGSize(width: 30, height: 30)
        static let interItemSpacing: CGFloat = 16
    }

    public typealias TargetAction = (target: Any?, selector: Selector)

    public struct Input {
        let image: UIImage?
        let action: TargetAction?
        let accessibilityLabel: String?

        public init(image: UIImage?, action: (target: Any?, selector: Selector)?, accessibilityLabel: String? = nil) {
            self.image = image
            self.action = action
            self.accessibilityLabel = accessibilityLabel
        }
    }

    public init(with input: [Input]) {
        super.init()

        let buttons = input.map { (input: Input) -> UIButton in
            UIButton(type: .system).then {
                $0.frame.size = Constants.buttonSize
                $0.imageView?.frame.size = Constants.buttonSize
                $0.setImage(input.image, for: .normal)
                $0.accessibilityLabel = self.accessibilityLabel
                if let action = input.action {
                    $0.addTarget(action.target, action: action.selector, for: .touchUpInside)
                }
            }
        }

        customView = UIStackView(arrangedSubviews: buttons)
            .with {
                $0.distribution = .fillProportionally
                $0.axis = .horizontal
                $0.alignment = .center
                $0.spacing = Constants.interItemSpacing
            }
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
