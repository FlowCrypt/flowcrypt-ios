//
//  RecipientEmailCollectionViewFlowLayout.swift
//  FlowCryptUI
//
//  Created by Ioan Moldovan on 4/15/22
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import UIKit

public class RecipientEmailCollectionViewFlowLayout: UICollectionViewFlowLayout {
    private(set) var maxY: CGFloat = -1.0 {
        didSet {
            onHeightChanged?(maxY)
        }
    }

    var onHeightChanged: ((CGFloat) -> Void)?
    let minRecipientInputWidth: CGFloat = 80

    override public func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        let attributes = super.layoutAttributesForElements(in: rect)
        var prevMaxY: CGFloat = 0
        var leftMargin = sectionInset.left

        let layoutAttributes = (attributes ?? [])
        for layoutAttribute in layoutAttributes {
            guard layoutAttribute.representedElementCategory == .cell else {
                continue
            }

            if layoutAttribute.frame.origin.y >= prevMaxY {
                leftMargin = sectionInset.left
            }

            // This is for recipient email input
            if layoutAttribute.indexPath.row == layoutAttributes.count - 1 {
                if rect.width - leftMargin < minRecipientInputWidth {
                    leftMargin = sectionInset.left
                    layoutAttribute.frame.origin.y += layoutAttribute.frame.height + minimumLineSpacing
                }
                let inputWidth = rect.width - leftMargin
                layoutAttribute.frame.origin.x = leftMargin + inputWidth / 2
                layoutAttribute.size.width = inputWidth
            } else {
                layoutAttribute.frame.origin.x = leftMargin
            }

            leftMargin += layoutAttribute.frame.width + minimumInteritemSpacing
            prevMaxY = layoutAttribute.frame.maxY
        }

        maxY = prevMaxY
        return attributes
    }
}
