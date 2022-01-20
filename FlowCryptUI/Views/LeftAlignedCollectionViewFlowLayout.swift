//
//  LeftAlignedCollectionViewFlowLayout.swift
//  FlowCryptUI
//
//  Created by Roma Sosnovsky on 21/10/21
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//
    

import UIKit

class LeftAlignedCollectionViewFlowLayout: UICollectionViewFlowLayout {
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        let attributes = super.layoutAttributesForElements(in: rect)
        var prevMaxY: CGFloat = 0

        attributes?.forEach { layoutAttribute in
            guard layoutAttribute.representedElementCategory == .cell else {
                return
            }

            layoutAttribute.frame.origin.x = sectionInset.left
            layoutAttribute.frame.origin.y = prevMaxY

            prevMaxY = layoutAttribute.frame.maxY
        }

        return attributes
    }
}

