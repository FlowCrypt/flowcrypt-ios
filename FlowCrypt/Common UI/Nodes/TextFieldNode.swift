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
        textField.text ?? ""
    }

    var attributedText: NSAttributedString? {
        didSet {
            DispatchQueue.main.async {
                self.textField.attributedText = self.attributedText
            }
        }
    }

    var isLowercased = false {
        didSet {
            DispatchQueue.main.async {
                if self.isLowercased {
                    self.textField.addTarget(
                        self,
                        action: #selector(self.onEditingChanged),
                        for: UIControl.Event.editingChanged
                    )
                } else {
                    self.textField.removeTarget(self, action: nil, for: UIControl.Event.editingChanged)
                }
            }
        }
    }

    private var height: CGFloat?

    private lazy var node = ASDisplayNode { UITextField() }

    init(prefferedHeight: CGFloat?) {
        super.init()
        addSubnode(node)
    }

    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        node.style.preferredSize = CGSize(width: constrainedSize.max.width, height: height ?? 40.0)
        return ASInsetLayoutSpec(insets: .zero, child: node)
    }

    private func addTarget(_ target: Any?, action: Selector, for event: UIControl.Event) {
        DispatchQueue.main.async {
            self.textField.addTarget(target, action: action, for: event)
        }
    }

    @objc private func onEditingChanged() {
        guard let attributedText = textField.attributedText, attributedText.string.isNotEmpty else { return }
        textField.attributedText = NSAttributedString(
            string: attributedText.string.lowercased(),
            attributes: attributedText.attributes(at: 0, effectiveRange: nil)
        )
    }

    @discardableResult
    override func becomeFirstResponder() -> Bool {
        DispatchQueue.main.async {
            super.becomeFirstResponder()
            _ = self.textField.becomeFirstResponder()
        }
        return true
    }
}

