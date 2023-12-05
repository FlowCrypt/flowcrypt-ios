//
// © 2017-2019 FlowCrypt Limited. All rights reserved.
//

import UIKit

public extension UIView {
    func constrainToEdges(_ subview: UIView, insets: UIEdgeInsets = .zero) {
        subview.translatesAutoresizingMaskIntoConstraints = false

        let guide = self.safeAreaLayoutGuide
        subview.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -insets.right).isActive = true
        subview.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: insets.left).isActive = true
        subview.topAnchor.constraint(equalTo: guide.topAnchor, constant: insets.top).isActive = true
        subview.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -insets.bottom).isActive = true
    }
}

// MARK: - UITextField

public extension UITextField {
    func setTextInset(_ left: CGFloat = 7) {
        leftView = UIView(frame: CGRect(x: 0, y: 0, width: left, height: frame.size.height))
        leftViewMode = .always
    }
}
