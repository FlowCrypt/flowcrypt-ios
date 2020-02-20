//
//  TextFieldNode.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 31.10.2019.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import AsyncDisplayKit

public enum TextFieldActionType {
    case didEndEditing(String?)
    case didBeginEditing(String?)
    case editingChanged(String?)
    /// event fired on backspace tap with (isEmpty value)
    case deleteBackward(Bool)
}

public typealias TextFieldAction = (TextFieldActionType) -> Void

final class TextField: UITextField {
    var onBackspaceTap: ((_ isEmpty: Bool) -> Void)?

    override func deleteBackward() {
        onBackspaceTap?(text == "")
        super.deleteBackward()
    }
}

final public class TextFieldNode: ASDisplayNode {

    public var shouldEndEditing: ((UITextField) -> (Bool))?

    private var textField: TextField {
        node.view as! TextField
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

    var shouldReturn: ((UITextField) -> (Bool))?

    private lazy var node = ASDisplayNode { TextField() }

    private var textFiledAction: TextFieldAction?

    public init(prefferedHeight: CGFloat?, action: TextFieldAction? = nil) {
        super.init()
        addSubnode(node)
        textFiledAction = action
        setupTextField()
    }

    private func setupTextField() {
        DispatchQueue.main.async {
            self.textField.delegate = self
            self.textField.addTarget(
                self,
                action: #selector(self.onEditingChanged),
                for: UIControl.Event.editingChanged
            )
            self.textField.onBackspaceTap = { [weak self] isEmpty in
                self?.textFiledAction?(.deleteBackward(isEmpty))
            }
        }
    }

    override public func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        return ASInsetLayoutSpec(insets: .zero, child: node)
    }

    private func addTarget(_ target: Any?, action: Selector, for event: UIControl.Event) {
        DispatchQueue.main.async {
            self.textField.addTarget(target, action: action, for: event)
        }
    }

    @objc private func onEditingChanged() {
        textFiledAction?(.editingChanged(textField.attributedText?.string ?? textField.text))

        if self.isLowercased {
            guard let attributedText = textField.attributedText, attributedText.string.isNotEmpty else { return }
            textField.attributedText = NSAttributedString(
                string: attributedText.string.lowercased(),
                attributes: attributedText.attributes(at: 0, effectiveRange: nil)
            )
        }
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

extension TextFieldNode: UITextFieldDelegate {
    public func textFieldDidBeginEditing(_ textField: UITextField) {
        textFiledAction?(.didBeginEditing(textField.text))
    }

    public func textFieldDidEndEditing(_ textField: UITextField) {
        textFiledAction?(.didEndEditing(textField.text))
    }

    public func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        return shouldEndEditing?(textField) ?? true
    }

    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return shouldReturn?(textField) ?? true
    }
}
