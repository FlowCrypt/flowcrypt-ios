//
// © 2017-2019 FlowCrypt Limited. All rights reserved.
//

import UIKit

extension UIView {
    // TODO: Anton - replace this
    func setViewBorder(_ borderWidth: CGFloat, borderColor: UIColor, cornerRadius: CGFloat) {
        layer.borderWidth = borderWidth
        layer.borderColor = borderColor.cgColor
        layer.cornerRadius = cornerRadius
    }
}

extension UITextField {
    func setTextInset(_ left: CGFloat = 7) {
        leftView = UIView(frame: CGRect(x: 0, y: 0, width: left, height: frame.size.height))
        leftViewMode = .always
    }
}
