//
//  TextFieldNode.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 31.10.2019.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import AsyncDisplayKit

final class TextFieldNode: ASDisplayNode {
    private var textField: UITextField {
        node.view as! UITextField
    }

    var attributedPlaceholderText: NSAttributedString? {
        didSet {
            DispatchQueue.main.async {
                self.textField.attributedPlaceholder = self.attributedPlaceholderText
            }
        }
    }

    var delegate: UITextFieldDelegate? {
        didSet {
            DispatchQueue.main.async {
                self.textField.delegate = self.delegate
            }
        }
    }

    var isSecureTextEntry: Bool = false {
        didSet {
            DispatchQueue.main.async {
                self.textField.isSecureTextEntry = self.isSecureTextEntry
            }
        }
    }

    var textAlignment: NSTextAlignment = .center {
        didSet {
            DispatchQueue.main.async {
                self.textField.textAlignment = self.textAlignment
            }
        }
    }

    var textInsets: CGFloat = -7 {
        didSet {
            DispatchQueue.main.async {
                self.textField.setTextInset(self.textInsets)
            }
        }
    }

    var text: String {
        return textField.text ?? ""
    }

    private lazy var node = ASDisplayNode { UITextField() }

    override init() {
        super.init()
        addSubnode(node)


    }

    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        node.style.preferredSize = CGSize(width: constrainedSize.max.width, height: 30)
        return ASInsetLayoutSpec(insets: .zero, child: node)
    }

    func addTarget(_ target: Any?, action: Selector, for event: UIControl.Event) {
        DispatchQueue.main.async {
            self.textField.addTarget(target, action: action, for: event)
        }
    }
}

