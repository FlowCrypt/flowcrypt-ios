//
// © 2017-2019 FlowCrypt Limited. All rights reserved.
//

import UIKit

public extension UIView {
    @discardableResult
    func bordered(color: UIColor, width: CGFloat) -> Self {
        layer.borderColor = color.cgColor
        layer.borderWidth = width
        return self
    }

    @discardableResult
    func cornered(_ cornerRadius: CGFloat) -> Self {
        layer.cornerRadius = cornerRadius
        return self
    }
}

public func borderStyle(color: UIColor, width: CGFloat) -> (UIView) -> Void {
  return {
    $0.layer.borderColor = color.cgColor
    $0.layer.borderWidth = width
  }
}

public extension UITextField {
    func setTextInset(_ left: CGFloat = 7) {
        leftView = UIView(frame: CGRect(x: 0, y: 0, width: left, height: frame.size.height))
        leftViewMode = .always
    }

    func setTextInsets(_ insets: UIEdgeInsets) {
        leftView = UIView(frame: CGRect(x: 0, y: 0, width: insets.left, height: frame.size.height))
        leftViewMode = .always

        rightView = UIView(frame: CGRect(x: 0, y: 0, width: insets.right, height: frame.size.height))
        rightViewMode = .always
    }
}
