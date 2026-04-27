//
//  TableViewController.swift
//  FlowCryptUI
//
//  Created by Anton Kharchevskyi on 18.10.2020.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import AsyncDisplayKit
import FlowCryptCommon

@MainActor
open class TableNodeViewController: ASDKViewController<TableNode> {
    private var renderedViewSize: CGSize = .zero

    override public var title: String? {
        didSet {
            navigationItem.setAccessibility(id: title)
        }
    }

    override public func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard
            let previousTraitCollection,
            isViewLoaded,
            view.window != nil
        else {
            return
        }

        let needsReload =
            traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection)
                || traitCollection.preferredContentSizeCategory != previousTraitCollection.preferredContentSizeCategory
                || traitCollection.horizontalSizeClass != previousTraitCollection.horizontalSizeClass
                || traitCollection.verticalSizeClass != previousTraitCollection.verticalSizeClass

        guard needsReload else { return }

        node.reloadData()
    }

    override open func viewDidLoad() {
        super.viewDidLoad()
        Logger.nested(Self.self).logDebug("View did load")
    }

    override open func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        guard isViewLoaded, view.window != nil else { return }

        let currentSize = view.bounds.size
        defer { renderedViewSize = currentSize }

        guard renderedViewSize != .zero, renderedViewSize != currentSize else { return }

        node.reloadData()
    }

    // MARK: - Keyboard
    public func observeKeyboardNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(adjustForKeyboard),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(adjustForKeyboard),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }

    @objc open func adjustForKeyboard(notification: Notification) {
        let height = self.keyboardHeight(from: notification)
        let insets = UIEdgeInsets(top: 0, left: 0, bottom: height + 5, right: 0)
        node.contentInset = insets
    }
}

public extension UINavigationItem {
    func setAccessibility(id: String?) {
        let titleColor: UIColor = if #available(iOS 26.0, *) {
            .main
        } else {
            .white
        }
        let titleLabel = UILabel()
        titleLabel.attributedText = id?.attributed(
            .medium(16),
            color: titleColor,
            alignment: .center
        )
        titleLabel.sizeToFit()
        titleView = titleLabel

        let identifier = (id ?? "").replacingOccurrences(of: " ", with: "-").lowercased()
        titleLabel.isAccessibilityElement = true
        titleLabel.accessibilityTraits = .header
        titleView?.accessibilityIdentifier = "aid-navigation-item-\(identifier)"
        titleView?.isAccessibilityElement = true
        titleView?.accessibilityTraits = .header
        isAccessibilityElement = true
    }
}
