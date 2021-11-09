//
//  NavigationBarItemsView.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 8/23/19.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
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
        @available(*, deprecated, message: "Use onTap closure instead")
        let action: TargetAction?
        let accessibilityLabel: String?
        let onTap: (() -> Void)?

        public init(
            image: UIImage?,
            action: (target: Any?, selector: Selector)? = nil,
            accessibilityLabel: String? = nil,
            onTap: (() -> Void)? = nil
        ) {
            self.image = image
            self.action = action
            self.accessibilityLabel = accessibilityLabel
            self.onTap = onTap
        }
    }

    private let input: [Input]

    public init(with input: [Input]) {
        self.input = input
        super.init()

        let buttons = input.enumerated()
            .map { value -> UIButton in
                UIButton(type: .system).then {
                    $0.tag = value.offset
                    $0.frame.size = Constants.buttonSize
                    $0.imageView?.frame.size = Constants.buttonSize
                    $0.setImage(value.element.image, for: .normal)
                    $0.accessibilityLabel = self.accessibilityLabel
                    if let action = value.element.action {
                        $0.addTarget(action.target, action: action.selector, for: .touchUpInside)
                    } else if value.element.onTap != nil {
                        $0.addTarget(self, action: #selector(self.handleTap(with:)), for: .touchUpInside)
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

    public override var isEnabled: Bool {
        didSet {
            customView?.alpha = isEnabled ? 1 : 0.5
        }
    }

    @objc private func handleTap(with button: UIButton) {
        input[button.tag].onTap?()
    }
}
