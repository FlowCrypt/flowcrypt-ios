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
        let title: String?
        let accessibilityId: String?
        let onTap: (() -> Void)?

        public init(
            image: UIImage?,
            title: String? = nil,
            accessibilityId: String? = nil,
            onTap: (() -> Void)? = nil
        ) {
            self.image = image
            self.title = title
            self.accessibilityId = accessibilityId
            self.onTap = onTap
        }
    }

    private let input: [Input]

    public init(with input: [Input]) {
        self.input = input
        super.init()

        if #available(iOS 26.0, *), input.count == 1 {
            configureNativeBarButtonItem(with: input[0])
            return
        }

        let buttons = input.enumerated()
            .map { value in
                UIButton(type: .system).then {
                    $0.tag = value.offset
                    $0.frame.size = Constants.buttonSize
                    $0.imageView?.frame.size = Constants.buttonSize
                    $0.setImage(value.element.image, for: .normal)
                    $0.setTitle(value.element.title, for: .normal)
                    $0.accessibilityIdentifier = value.element.accessibilityId
                    $0.isAccessibilityElement = true
                    $0.addTarget(self, action: #selector(self.handleTap(with:)), for: .touchUpInside)
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

    override public var isEnabled: Bool {
        didSet {
            customView?.alpha = isEnabled ? 1 : 0.5
        }
    }

    @objc private func handleTap(with button: UIButton) {
        input[button.tag].onTap?()
    }

    @objc private func handleNativeTap() {
        input.first?.onTap?()
    }

    @available(iOS 26.0, *)
    private func configureNativeBarButtonItem(with input: Input) {
        image = input.image
        title = input.title
        accessibilityIdentifier = input.accessibilityId
        isAccessibilityElement = true
        target = self
        action = #selector(handleNativeTap)
    }
}

public extension UINavigationItem {
    func setRightNavigationBarItems(with input: [NavigationBarItemsView.Input]) {
        if #available(iOS 26.0, *) {
            rightBarButtonItems = input
                .reversed()
                .map { NavigationBarItemsView(with: [$0]) }
        } else {
            rightBarButtonItem = NavigationBarItemsView(with: input)
        }
    }
}
