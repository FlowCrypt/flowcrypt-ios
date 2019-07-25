//
// © 2017-2019 FlowCrypt Limited. All rights reserved.
//

import UIKit

extension UIView {
    func setViewBorder(_ borderWidth: CGFloat, borderColor: UIColor, cornerRadius: CGFloat) {
        self.layer.borderWidth = borderWidth
        self.layer.borderColor = borderColor.cgColor
        self.layer.cornerRadius = cornerRadius
    }
}
