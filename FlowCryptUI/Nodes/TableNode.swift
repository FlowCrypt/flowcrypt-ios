//
//  TableNode.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 31.10.2019.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import AsyncDisplayKit

public final class TableNode: ASTableNode {
    public override init(style: UITableView.Style) {
        super.init(style: style)
        view.showsVerticalScrollIndicator = false
        view.separatorStyle = .none
        view.keyboardDismissMode = .onDrag
        backgroundColor = .backgroundColor
    }

    public var bounces: Bool = true {
        didSet {
            DispatchQueue.main.async {
                self.view.bounces = self.bounces
            }
        }
    }

    public override func asyncTraitCollectionDidChange(
        withPreviousTraitCollection previousTraitCollection: ASPrimitiveTraitCollection
    ) {
        super.asyncTraitCollectionDidChange(withPreviousTraitCollection: previousTraitCollection)
        guard #available(iOS 13.0, *) else { return }
        backgroundColor = .backgroundColor
    }

    public override func reloadData() {
        DispatchQueue.main.async {
            super.reloadData()
        }
    }

}
