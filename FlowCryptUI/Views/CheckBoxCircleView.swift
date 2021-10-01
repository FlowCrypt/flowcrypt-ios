//
//  CheckBoxCircleView.swift
//  FlowCryptUI
//
//  Created by Anton Kharchevskyi on 27/09/2020.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import UIKit

final class CheckBoxCircleView: UIView {
    var strokeWidth: CGFloat = 2 { didSet { setNeedsDisplay() } }
    var innerInset: CGFloat = 10 { didSet { setNeedsDisplay() } }

    var outerColor: UIColor = .red { didSet { setNeedsDisplay() } }
    var innerColor: UIColor = .green { didSet { setNeedsDisplay() } }

    override func draw(_ rect: CGRect) {
        let outerPath = UIBezierPath(
            ovalIn: rect.insetBy(dx: strokeWidth, dy: strokeWidth)
        )
        outerColor.setStroke()
        outerPath.lineWidth = strokeWidth
        outerPath.stroke()

        let dx = innerInset + strokeWidth
        let innerPath = UIBezierPath(
            ovalIn: rect.insetBy(dx: dx, dy: dx)
        )
        innerColor.setFill()
        innerPath.fill()

        backgroundColor = .clear
    }
}
