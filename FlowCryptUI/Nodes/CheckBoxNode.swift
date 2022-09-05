//
//  CheckBoxNode.swift
//  FlowCryptUI
//
//  Created by Anton Kharchevskyi on 27/09/2020.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import AsyncDisplayKit

public final class CheckBoxNode: ASDisplayNode {
    public struct Input {
        let color: UIColor
        let strokeWidth: CGFloat

        public init(
            color: UIColor,
            strokeWidth: CGFloat
        ) {
            self.color = color
            self.strokeWidth = strokeWidth
        }
    }

    public convenience init(_ input: Input) {
        self.init { () -> UIView in
            let view = CheckBoxCircleView()
            view.innerColor = input.color
            view.outerColor = input.color
            view.innerInset = 4
            view.strokeWidth = input.strokeWidth
            view.backgroundColor = .clear
            return view
        }
    }
}
