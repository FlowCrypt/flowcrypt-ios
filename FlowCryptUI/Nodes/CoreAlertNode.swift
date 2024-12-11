//
//  CoreAlertNode.swift
//  FlowCrypt
//
//  Created by Ioan Moldovan on 12/10/24
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import AsyncDisplayKit

public class CoreAlertNode: ASDisplayNode {

    enum Constants {
        static let antiBruteForceProtectionAttemptsMaxValue = 5
        static let blockingTimeInSeconds: Double = 5 * 60
        static let buttonFont = UIFont.systemFont(ofSize: 16)
        static let submitButtonText = "submit".localized
        static let cancelButtonText = "cancel".localized
    }

    func createContentView() -> ASDisplayNode {
        let node = ASDisplayNode()
        node.backgroundColor = UIColor.colorFor(
            darkStyle: UIColor(hex: "282828") ?? .black,
            lightStyle: UIColor(hex: "F0F0F0") ?? .white
        )
        node.clipsToBounds = true
        node.cornerRadius = 13
        node.shadowColor = UIColor.black.cgColor
        node.shadowRadius = 15
        node.shadowOpacity = 0.1
        node.shadowOffset = CGSize(width: 0, height: 2)
        return node
    }

    func createOverlayNode() -> ASDisplayNode {
        let node = ASDisplayNode()
        node.backgroundColor = UIColor(white: 0, alpha: 0.4) // semi-transparent black
        return node
    }

    func createSeparatorNode() -> ASDisplayNode {
        let node = ASDisplayNode()
        node.backgroundColor = UIColor.separator
        node.style.height = ASDimension(unit: .points, value: 0.5)
        return node
    }

    func createTextNode(text: String, isBold: Bool, fontSize: CGFloat, identifier: String? = nil, detectLinks: Bool = false) -> ASTextNode {
        let node = ASTextNode()
        node.isUserInteractionEnabled = true

        let font = isBold ? UIFont.boldSystemFont(ofSize: fontSize) : UIFont.systemFont(ofSize: fontSize)
        let attributedString = NSMutableAttributedString(
            string: text,
            attributes: [
                .font: font,
                .foregroundColor: UIColor.mainTextColor
            ]
        )

        if detectLinks {
            let types: NSTextCheckingResult.CheckingType = .link
            if let detector = try? NSDataDetector(types: types.rawValue) {
                let matches = detector.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count))
                for match in matches {
                    if let url = match.url, let range = Range(match.range, in: text) {
                        attributedString.addAttribute(.link, value: url, range: NSRange(range, in: text))
                    }
                }
            }
        }

        node.attributedText = attributedString
        node.accessibilityIdentifier = identifier
        return node
    }

    func createButtonNode(title: String, color: UIColor, identifier: String, action: Selector) -> ASButtonNode {
        let node = ASButtonNode()
        node.setTitle(title, with: Constants.buttonFont, with: color, for: .normal)
        node.style.flexGrow = 1
        node.style.preferredSize.height = 35
        node.addTarget(self, action: action, forControlEvents: .touchUpInside)
        node.accessibilityIdentifier = identifier
        node.setBackgroundColor(UIColor.colorFor(darkStyle: .darkGray, lightStyle: .lightGray), forState: .highlighted)
        return node
    }
}
