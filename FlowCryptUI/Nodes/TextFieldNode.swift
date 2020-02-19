//
//  TextFieldNode.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 31.10.2019.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import AsyncDisplayKit

final public class TextFieldNode: ASDisplayNode {
    private var textField: UITextField {
        node.view as! UITextField
    }

    public var attributedPlaceholderText: NSAttributedString? {
        didSet {
            DispatchQueue.main.async {
                self.textField.attributedPlaceholder = self.attributedPlaceholderText
            }
        }
    }

    public var delegate: UITextFieldDelegate? {
        didSet {
            DispatchQueue.main.async {
                self.textField.delegate = self.delegate
            }
        }
    }

    public var isSecureTextEntry: Bool = false {
        didSet {
            DispatchQueue.main.async {
                self.textField.isSecureTextEntry = self.isSecureTextEntry
            }
        }
    }

    public var textAlignment: NSTextAlignment = .center {
        didSet {
            DispatchQueue.main.async {
                self.textField.textAlignment = self.textAlignment
            }
        }
    }

    public var textInsets: CGFloat = -7 {
        didSet {
            DispatchQueue.main.async {
                self.textField.setTextInset(self.textInsets)
            }
        }
    }

    public var text: String {
        textField.text ?? ""
    }

    public var attributedText: NSAttributedString? {
        didSet {
            DispatchQueue.main.async {
                self.textField.attributedText = self.attributedText
            }
        }
    }

    public var isLowercased = false {
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

    public init(prefferedHeight: CGFloat?) {
        super.init()
        addSubnode(node)
    }

    override public func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
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
    override public func becomeFirstResponder() -> Bool {
        DispatchQueue.main.async {
            super.becomeFirstResponder()
            _ = self.textField.becomeFirstResponder()
        }
        return true
    }
}

