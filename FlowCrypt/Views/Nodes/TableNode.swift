//
//  TableNode.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 31.10.2019.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import AsyncDisplayKit

final class TableNode: ASTableNode {
    override init(style: UITableView.Style) {
        super.init(style: style)
        view.showsVerticalScrollIndicator = false
        view.separatorStyle = .none
        view.keyboardDismissMode = .onDrag
    }
}
