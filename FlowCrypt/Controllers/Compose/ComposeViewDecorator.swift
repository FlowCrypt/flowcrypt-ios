//
//  ComposeDecorator.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 05.11.2019.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import FlowCryptUI
import UIKit

typealias RecipientState = RecipientEmailsCellNode.Input.State
typealias RecipientStateContext = RecipientEmailsCellNode.Input.StateContext

struct ComposeViewDecorator {
    let recipientIdleState: RecipientState = .idle(idleStateContext)
    let recipientSelectedState: RecipientState = .selected(selectedStateContext)
    let recipientKeyFoundState: RecipientState = .keyFound(keyFoundStateContext)
    let recipientKeyNotFoundState: RecipientState = .keyNotFound(keyNotFoundStateContext)
    let recipientErrorState: RecipientState = .error(errorStateContext, false)
    var recipientErrorStateRetry: RecipientState = .error(errorStateContextWithRetry, true)

    func styledTextViewInput(with height: CGFloat) -> TextViewCellNode.Input {
        TextViewCellNode.Input(
            placeholder: "message_compose_secure".localized.attributed(
                .regular(17),
                color: .lightGray,
                alignment: .left
            ),
            preferredHeight: height,
            textColor: .mainTextColor
        )
    }

    func styledTextFieldInput(with text: String, keyboardType: UIKeyboardType = .default) -> TextFieldCellNode.Input {
        TextFieldCellNode.Input(
            placeholder: text.localized.attributed(
                .regular(17),
                color: .lightGray,
                alignment: .left
            ),
            isSecureTextEntry: false,
            textInsets: -8,
            textAlignment: .left,
            height: 40,
            width: UIScreen.main.bounds.width,
            keyboardType: keyboardType
        )
    }

    func styledTitle(with text: String?) -> NSAttributedString? {
        guard let text = text else { return nil }
        return text.attributed(.regular(17))
    }

    func styledRecipientInfo(with email: String) -> InfoCellNode.Input {
        InfoCellNode.Input(
            attributedText: email.attributed(
                .medium(17),
                color: UIColor.black.withAlphaComponent(0.8),
                alignment: .left
            ),
            image: nil,
            insets: UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        )
    }

    func styledReplyQuote(with input: ComposeMessageInput) -> NSAttributedString {
        guard case let .reply(info) = input.type else { return NSAttributedString(string: "") }

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .none

        let date = dateFormatter.string(from: info.sentDate)

        dateFormatter.dateStyle = .none
        dateFormatter.timeStyle = .short
        let time = dateFormatter.string(from: info.sentDate)

        let from = info.recipient ?? "unknown sender"

        let text: String = "\n\n"
            + "compose_reply_from".localizeWithArguments(date, time, from)
            + "\n"

        let message = " > " + info.message.replacingOccurrences(of: "\n", with: "\n > ")

        return (text + message).attributed(.regular(17))
    }
}

// MARK: - Color
extension UIColor {
    static var titleNodeBackgroundColorSelected: UIColor {
        UIColor.colorFor(
            darkStyle: UIColor.lightGray,
            lightStyle: UIColor.black.withAlphaComponent(0.1)
        )
    }

    static var titleNodeBackgroundColor: UIColor {
        UIColor.colorFor(
            darkStyle: UIColor.darkGray.withAlphaComponent(0.5),
            lightStyle: UIColor.white.withAlphaComponent(0.9)
        )
    }

    static var borderColorSelected: UIColor {
        UIColor.colorFor(
            darkStyle: UIColor.white.withAlphaComponent(0.5),
            lightStyle: black.withAlphaComponent(0.4)
        )
    }

    static var borderColor: UIColor {
        UIColor.colorFor(
            darkStyle: UIColor.white.withAlphaComponent(0.5),
            lightStyle: UIColor.black.withAlphaComponent(0.3)
        )
    }
}

// MARK: - RecipientState
extension ComposeViewDecorator {
    static var idleStateContext: RecipientStateContext {
        RecipientStateContext(
            backgroundColor: .titleNodeBackgroundColor,
            borderColor: .borderColor,
            textColor: .mainTextColor,
            image: #imageLiteral(resourceName: "retry")
        )
    }

    private static var selectedStateContext: RecipientStateContext {
        RecipientStateContext(
            backgroundColor: .gray,
            borderColor: .borderColor,
            textColor: .white,
            image: nil
        )
    }

    private static var keyFoundStateContext: RecipientStateContext {
        RecipientStateContext(
            backgroundColor: .main,
            borderColor: .borderColor,
            textColor: .white,
            image: nil
        )
    }

    private static var keyNotFoundStateContext: RecipientStateContext {
        RecipientStateContext(
            backgroundColor: .titleNodeBackgroundColorSelected,
            borderColor: .borderColorSelected,
            textColor: .white,
            image: nil
        )
    }

    private static var errorStateContext: RecipientStateContext {
        RecipientStateContext(
            backgroundColor: .red,
            borderColor: .borderColor,
            textColor: .white,
            image: #imageLiteral(resourceName: "cancel")
        )
    }

    private static var errorStateContextWithRetry: RecipientStateContext {
        RecipientStateContext(
            backgroundColor: .red,
            borderColor: .borderColor,
            textColor: .white,
            image: #imageLiteral(resourceName: "retry")
        )
    }
}

// MARK: - RecipientEmailsCellNode.Input
extension RecipientEmailsCellNode.Input {
    init(_ recipient: ComposeMessageRecipient) {
        self.init(
            email: recipient.email.lowercased().attributed(
                .regular(17),
                color: recipient.state.textColor,
                alignment: .left
            ),
            state: recipient.state
        )
    }
}

// MARK: - AttachmentNode.Input
extension AttachmentNode.Input {
    init(composeAttachment: ComposeMessageAttachment) {
        self.init(
            name: composeAttachment.name
                .attributed(.regular(18), color: .textColor, alignment: .left),
            size: "\(composeAttachment.size)"
                .attributed(.medium(12), color: .textColor, alignment: .left)
        )
    }
}
