//
//  TableNode.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 31.10.2019.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import AsyncDisplayKit

public final class TableNode: ASTableNode {
    override public init(style: UITableView.Style) {
        super.init(style: style)
        view.showsVerticalScrollIndicator = false
        view.separatorStyle = .none
        view.keyboardDismissMode = .onDrag
        backgroundColor = .backgroundColor
    }

    public var bounces = true {
        didSet {
            DispatchQueue.main.async {
                self.view.bounces = self.bounces
            }
        }
    }

    override public func asyncTraitCollectionDidChange(
        withPreviousTraitCollection previousTraitCollection: ASPrimitiveTraitCollection
    ) {
        super.asyncTraitCollectionDidChange(withPreviousTraitCollection: previousTraitCollection)
        backgroundColor = .backgroundColor
    }

    override public func reloadData() {
        DispatchQueue.main.async {
            super.reloadData()
        }
    }
}

public extension UIViewController {
    var safeAreaWindowInsets: UIEdgeInsets {
        UIApplication.shared.keyWindow?.safeAreaInsets ?? .zero
    }
}

public extension UIViewController {
    /// should be called on a main thread
    func visibleSize(for tableNode: ASTableNode) -> CGSize {
        let height = tableNode.frame.size.height
            - (navigationController?.navigationBar.frame.size.height ?? 0.0)
            - safeAreaWindowInsets.top
            - safeAreaWindowInsets.bottom

        let size = CGSize(
            width: tableNode.frame.size.width,
            height: max(height, 0)
        )

        return size
    }
}
