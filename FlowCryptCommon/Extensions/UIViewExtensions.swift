//
// © 2017-2019 FlowCrypt Limited. All rights reserved.
//

import UIKit

public extension UIView {
    func constrainToEdges(_ subview: UIView, insets: UIEdgeInsets = .zero) {
        subview.translatesAutoresizingMaskIntoConstraints = false

        let topConstraint = NSLayoutConstraint(
            item: subview,
            attribute: .top,
            relatedBy: .equal,
            toItem: self,
            attribute: .top,
            multiplier: 1.0,
            constant: insets.top
        )

        let bottomConstraint = NSLayoutConstraint(
            item: subview,
            attribute: .bottom,
            relatedBy: .equal,
            toItem: self,
            attribute: .bottom,
            multiplier: 1.0,
            constant: -insets.bottom
        )

        let leadingConstraint = NSLayoutConstraint(
            item: subview,
            attribute: .leading,
            relatedBy: .equal,
            toItem: self,
            attribute: .leading,
            multiplier: 1.0,
            constant: insets.left
        )

        let trailingConstraint = NSLayoutConstraint(
            item: subview,
            attribute: .trailing,
            relatedBy: .equal,
            toItem: self,
            attribute: .trailing,
            multiplier: 1.0,
            constant: -insets.right
        )

        addConstraints([
            topConstraint,
            bottomConstraint,
            leadingConstraint,
            trailingConstraint
        ])
    }
}

// MARK: - UITextField

public extension UITextField {
    func setTextInset(_ left: CGFloat = 7) {
        leftView = UIView(frame: CGRect(x: 0, y: 0, width: left, height: frame.size.height))
        leftViewMode = .always
    }
}
