//
//  CellNode.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 31.10.2019.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import AsyncDisplayKit

open class CellNode: ASCellNode {
    var leftBorder: ASDisplayNode?

    func addLeftBorder(width: CGFloat, color: UIColor?) {
        let border = ASDisplayNode()
        border.backgroundColor = color
        border.style.width = ASDimension(unit: .points, value: width)
        border.style.height = ASDimension(unit: .fraction, value: 1)
        addSubnode(border)
        leftBorder = border
    }

    override public func layout() {
        super.layout()
        let leftBorderWidth = leftBorder?.style.width.value ?? 0
        leftBorder?.frame = CGRect(x: 0, y: 0, width: leftBorderWidth, height: self.bounds.height)
    }

    override public init() {
        super.init()
        automaticallyManagesSubnodes = true
        selectionStyle = .none
        backgroundColor = .backgroundColor
    }
}
