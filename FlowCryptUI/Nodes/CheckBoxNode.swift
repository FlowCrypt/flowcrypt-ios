//
//  CheckBoxNode.swift
//  FlowCryptUI
//
//  Created by Anton Kharchevskyi on 27/09/2020.
//  Copyright © 2020 FlowCrypt Limited. All rights reserved.
//

import AsyncDisplayKit

final public class CheckBoxNode: ASDisplayNode {
    public struct Input {
        let color: UIColor
        let disabledColor: UIColor
        let strokeWidth: CGFloat

        public init(
            color: UIColor,
            disabledColor: UIColor,
            strokeWidth: CGFloat
        ) {
            self.color = color
            self.disabledColor = disabledColor
            self.strokeWidth = strokeWidth
        }
    }

    public convenience init(_ input: Input) {
        self.init { () -> UIView in
            let view = CheckBoxCircleView()
            view.innerColor = input.color
            view.strokeWidth = input.strokeWidth
            return view
        }
    }
}
