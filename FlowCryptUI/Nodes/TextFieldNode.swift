//
//  TextFieldNode.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 31.10.2019.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import AsyncDisplayKit

public enum TextFieldActionType {
    case didEndEditing(String?)
    case didBeginEditing(String?)
    case editingChanged(String?)
    case didPaste(UITextField, String?)
    case deleteBackward(UITextField)
}

public typealias TextFieldAction = (TextFieldActionType) -> Void

final class TextField: UITextField {
    var onBackspaceTap: (() -> Void)?

    override func deleteBackward() {
        onBackspaceTap?()
        super.deleteBackward()
    }
}

public final class TextFieldNode: ASDisplayNode {
    public typealias ShouldChangeAction = (UITextField, String) -> (Bool)
    public typealias ShouldEndEditingAction = (UITextField) -> (Bool)
    public typealias ShouldReturnAction = (UITextField) -> (Bool)

    var shouldEndEditing: ShouldEndEditingAction?
    var shouldReturn: ShouldReturnAction?
    var shouldChangeCharacters: ShouldChangeAction?

    // swiftlint:disable force_cast
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

    public var isSecureTextEntry = false {
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

    override public var isUserInteractionEnabled: Bool {
        didSet {
            DispatchQueue.main.async {
                self.textField.isUserInteractionEnabled = self.isUserInteractionEnabled
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
        get {
            textField.text ?? ""
        }
        set {
            textField.text = newValue
        }
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
                        for: .editingChanged
                    )
                } else {
                    self.textField.removeTarget(self, action: nil, for: .editingChanged)
                }
            }
        }
    }

    public var keyboardType: UIKeyboardType = .default {
        didSet {
            DispatchQueue.main.async {
                self.textField.keyboardType = self.keyboardType
            }
        }
    }

    public var autocapitalizationType: UITextAutocapitalizationType = .sentences {
        didSet {
            DispatchQueue.main.async {
                self.textField.autocapitalizationType = self.autocapitalizationType
            }
        }
    }

    private lazy var node = ASDisplayNode { TextField() }

    private var textFieldAction: TextFieldAction?

    private var onToolbarDoneAction: (() -> Void)?

    public init(accessibilityIdentifier: String?, action: TextFieldAction? = nil) {
        super.init()
        addSubnode(node)
        textFieldAction = action
        setupTextField(with: accessibilityIdentifier)
    }

    private func setupTextField(with accessibilityIdentifier: String?) {
        DispatchQueue.main.async {
            self.textField.delegate = self
            self.textField.addTarget(
                self,
                action: #selector(self.onEditingChanged),
                for: .editingChanged
            )
            self.textField.onBackspaceTap = { [weak self] in
                guard let self else { return }
                self.textFieldAction?(.deleteBackward(self.textField))
            }
            self.textField.accessibilityIdentifier = accessibilityIdentifier
        }
    }

    override public func layoutSpecThatFits(_: ASSizeRange) -> ASLayoutSpec {
        ASInsetLayoutSpec(insets: .zero, child: node)
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

public extension TextFieldNode {
    func reset() {
        (node.view as? TextField)?.text = nil
    }
}

extension TextFieldNode {
    private func addTarget(_ target: Any?, action: Selector, for event: UIControl.Event) {
        DispatchQueue.main.async {
            self.textField.addTarget(target, action: action, for: event)
        }
    }

    @objc private func onEditingChanged() {
        textFieldAction?(.editingChanged(textField.attributedText?.string ?? textField.text))

        if isLowercased {
            guard let attributedText = textField.attributedText, attributedText.string.isNotEmpty else { return }
            textField.attributedText = NSAttributedString(
                string: attributedText.string.lowercased(),
                attributes: attributedText.attributes(at: 0, effectiveRange: nil)
            )
        }
    }
}

extension TextFieldNode: UITextFieldDelegate {
    public func textFieldDidBeginEditing(_ textField: UITextField) {
        textFieldAction?(.didBeginEditing(textField.text))
    }

    public func textFieldDidEndEditing(_ textField: UITextField) {
        textFieldAction?(.didEndEditing(textField.text))
    }

    public func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        shouldEndEditing?(textField) ?? true
    }

    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        shouldReturn?(textField) ?? true
    }

    public func textField(_ textField: UITextField, shouldChangeCharactersIn _: NSRange, replacementString string: String) -> Bool {
        if string.count > 1 {
            textFieldAction?(.didPaste(textField, string))
        }
        return shouldChangeCharacters?(textField, string) ?? true
    }
}

public extension TextFieldNode {
    func setPicker(view: UIPickerView?, withToolbar: Bool = true, onDone: (() -> Void)?) {
        DispatchQueue.main.async {
            guard let view else {
                self.textField.inputView = nil
                self.textField.inputAccessoryView = nil
                return
            }
            self.textField.inputView = view

            if withToolbar {
                self.setToolbar(onDone)
            }
        }
    }

    func setToolbar(_ onDone: (() -> Void)?) {
        onToolbarDoneAction = onDone
        let toolBar = UIToolbar(frame: CGRect(x: 0, y: 0, width: 100, height: 40))
        self.textField.sizeToFit()
        let doneButton = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(self.dismiss)
        )
        toolBar.setItems([doneButton], animated: false)
        toolBar.isUserInteractionEnabled = true
        self.textField.inputAccessoryView = toolBar
    }

    @objc private func dismiss() {
        onToolbarDoneAction?()
    }
}
