//
//  LeftAlignedCollectionViewFlowLayout.swift
//  FlowCryptUI
//
//  Created by Roma Sosnovsky on 21/10/21
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import UIKit

public class LeftAlignedCollectionViewFlowLayout: UICollectionViewFlowLayout {
    private(set) var maxY: CGFloat = -1.0 {
        didSet {
            onHeightChanged?(maxY)
        }
    }

    var onHeightChanged: ((CGFloat) -> Void)?

    override public func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        let attributes = super.layoutAttributesForElements(in: rect)
        var prevMaxY: CGFloat = 0
        var leftMargin = sectionInset.left

        for layoutAttribute in attributes ?? [] {
            guard layoutAttribute.representedElementCategory == .cell else {
                continue
            }

            if layoutAttribute.frame.origin.y >= prevMaxY {
                leftMargin = sectionInset.left
            }

            layoutAttribute.frame.origin.x = leftMargin

            leftMargin += layoutAttribute.frame.width + minimumInteritemSpacing
            prevMaxY = layoutAttribute.frame.maxY
        }

        maxY = prevMaxY
        return attributes
    }
}
