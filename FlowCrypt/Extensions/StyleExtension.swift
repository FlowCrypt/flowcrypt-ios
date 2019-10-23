//
//  StyleExtension.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 01.10.2019.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import UIKit

extension NSAttributedString {
    enum Style {
        case regular(CGFloat), medium(CGFloat), bold(CGFloat)

        var font: UIFont {
            switch self {
            case let .regular(size): return UIFont.systemFont(ofSize: size)
            case let .medium(size): return UIFont.systemFont(ofSize: size, weight: .medium)
            case let .bold(size): return UIFont.boldSystemFont(ofSize: size)
            }
        }
    }

    static func text(from string: String, style: Style, color: UIColor = .black) -> NSAttributedString {
        return NSAttributedString(
            string: string,
            attributes: [
                NSAttributedString.Key.font: style.font,
                NSAttributedString.Key.foregroundColor: color,
            ]
        )
    }
}

extension String {
    func attributed(_ style: NSAttributedString.Style, color: UIColor = .black) -> NSAttributedString {
        return NSAttributedString.text(from: self, style: style, color: color)
    }
}
