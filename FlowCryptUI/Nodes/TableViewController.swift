//
//  TableViewController.swift
//  FlowCryptUI
//
//  Created by Anton Kharchevskyi on 18.10.2020.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import AsyncDisplayKit

@MainActor
open class TableNodeViewController: ASDKViewController<TableNode> {
    public override var title: String? {
        didSet {
            navigationItem.setAccessibility(id: title)
        }
    }
    
    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        node.reloadData()
    }
}

public extension UINavigationItem {
    func setAccessibility(id: String?) {
        let titleLabel = UILabel()
        titleLabel.text = id
        titleLabel.isAccessibilityElement = true
        titleLabel.accessibilityIdentifier = title
        titleLabel.accessibilityLabel = title
        titleLabel.accessibilityTraits = .header
        titleLabel.backgroundColor = .red
        titleLabel.sizeToFit()
        titleView = titleLabel
    }
}
