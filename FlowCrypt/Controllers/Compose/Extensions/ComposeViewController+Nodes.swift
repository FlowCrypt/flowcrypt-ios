//
//  ComposeViewController+Nodes.swift
//  FlowCrypt
//
//  Created by Ioan Moldovan on 4/6/22
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import UIKit
import AsyncDisplayKit
import FlowCryptUI

// MARK: - Nodes
extension ComposeViewController {
    internal func recipientTextNode() -> ComposeRecipientCellNode {
        let recipients = contextToSend.recipients.map(RecipientEmailsCellNode.Input.init)
        let textNode = ComposeRecipientCellNode(
            input: ComposeRecipientCellNode.Input(recipients: recipients),
            accessibilityIdentifier: "aid-recipient-list-text",
            titleNodeBackgroundColorSelected: .titleNodeBackgroundColorSelected,
            tapAction: { [weak self] in
                self?.hideRecipientLabel()
            }
        )
        return textNode
    }

    internal func showRecipientLabelIfNecessary() {
        let isRecipientLoading = self.contextToSend.recipients.filter { $0.state == decorator.recipientIdleState }.isNotEmpty
        guard !isRecipientLoading,
              self.contextToSend.recipients.isNotEmpty,
              self.userTappedOutSideRecipientsArea else {
            return
        }
        if !self.shouldShowEmailRecipientsLabel {
            self.shouldShowEmailRecipientsLabel = true
            self.userTappedOutSideRecipientsArea = false
            self.reload(sections: [.recipientsLabel, .recipients(.to), .recipients(.cc), .recipients(.bcc)])
        }
    }

    internal func hideRecipientLabel() {
        self.shouldShowEmailRecipientsLabel = false
        self.reload(sections: [.recipientsLabel, .recipients(.to), .recipients(.cc), .recipients(.bcc)])
    }

    internal func subjectNode() -> ASCellNode {
        TextFieldCellNode(
            input: decorator.styledTextFieldInput(
                with: "compose_subject".localized,
                accessibilityIdentifier: "aid-subject-text-field"
            )
        ) { [weak self] event in
            switch event {
            case .editingChanged(let text), .didEndEditing(let text):
                self?.contextToSend.subject = text
            case .didBeginEditing:
                self?.userTappedOutSideRecipientsArea = true
                self?.showRecipientLabelIfNecessary()
            case .deleteBackward:
                return
            }
        }
        .onShouldReturn { [weak self] _ in
            guard let self = self else { return true }
            if !self.input.isQuote, let node = self.node.visibleNodes.compactMap({ $0 as? TextViewCellNode }).first {
                node.becomeFirstResponder()
            } else {
                self.node.view.endEditing(true)
            }
            return true
        }
        .then {
            $0.attributedText = decorator.styledTitle(with: contextToSend.subject)
        }
    }

    internal func messagePasswordNode() -> ASCellNode {
        let input = contextToSend.hasMessagePassword
        ? decorator.styledFilledMessagePasswordInput()
        : decorator.styledEmptyMessagePasswordInput()

        return MessagePasswordCellNode(
            input: input,
            setMessagePassword: { [weak self] in self?.setMessagePassword() }
        )
    }

    internal func textNode() -> ASCellNode {
        let styledQuote = decorator.styledQuote(with: input)
        let height = max(decorator.frame(for: styledQuote).height, 40)
        return TextViewCellNode(
            decorator.styledTextViewInput(
                with: height,
                accessibilityIdentifier: "aid-message-text-view"
            )
        ) { [weak self] event in
            guard let self = self else { return }
            switch event {
            case .didBeginEditing:
                self.userTappedOutSideRecipientsArea = true
                self.showRecipientLabelIfNecessary()
            case .editingChanged(let text), .didEndEditing(let text):
                self.contextToSend.message = text?.string
            case .heightChanged(let textView):
                self.ensureCursorVisible(textView: textView)
            }
        }
        .then {
            let messageText = decorator.styledMessage(with: contextToSend.message ?? "")
            let textNode = $0

            if input.isQuote && !messageText.string.contains(styledQuote.string) {
                let mutableString = NSMutableAttributedString(attributedString: messageText)
                mutableString.append(styledQuote)
                textNode.textView.attributedText = mutableString
                if input.isReply {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        textNode.becomeFirstResponder()
                    }
                }
            } else {
                DispatchQueue.main.async {
                    textNode.textView.attributedText = messageText
                }
            }
        }
    }

    internal func ensureCursorVisible(textView: UITextView) {
        guard let range = textView.selectedTextRange else { return }

        let cursorRect = textView.caretRect(for: range.start)

        var rectToMakeVisible = textView.convert(cursorRect, to: node.view)
        rectToMakeVisible.origin.y -= cursorRect.height
        rectToMakeVisible.size.height *= 3

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { // fix for animation lag
            self.node.view.scrollRectToVisible(rectToMakeVisible, animated: true)
        }
    }

    internal func recipientsNode(type: RecipientType) -> ASCellNode {
        let recipients = contextToSend.recipients(type: type)

        let shouldShowToggleButton = type == .to
            && recipients.isNotEmpty
            && !contextToSend.hasCcOrBccRecipients

        return RecipientEmailsCellNode(
            recipients: recipients.map(RecipientEmailsCellNode.Input.init),
            recipientInput: recipientInput(type: type),
            type: type.rawValue,
            height: decorator.recipientsNodeHeight(type: type) ?? Constants.minRecipientsPartHeight,
            isToggleButtonRotated: shouldShowAllRecipientTypes,
            toggleButtonAction: shouldShowToggleButton ? { [weak self] in
                guard type == .to else { return }
                self?.toggleRecipientsList()
            } : nil)
            .onLayoutHeightChanged { [weak self] layoutHeight in
                self?.decorator.updateRecipientsNode(
                    layoutHeight: layoutHeight,
                    type: type,
                    completion: {
                        if let indexPath = self?.recipientsIndexPath(type: type),
                           let emailNode = self?.node.nodeForRow(at: indexPath) as? RecipientEmailsCellNode {
                            emailNode.style.preferredSize.height = layoutHeight
                            emailNode.setNeedsLayout()
                        }
                    }
                )
            }
            .onItemSelect { [weak self] (action: RecipientEmailsCellNode.RecipientEmailTapAction) in
                switch action {
                case let .imageTap(indexPath):
                    self?.handleRecipientAction(with: indexPath, type: type)
                case let .select(indexPath, sender):
                    self?.handleRecipientSelection(with: indexPath, type: type)
                    self?.displayRecipientPopOver(with: indexPath, type: type, sender: sender)
                }
            }
    }

    internal func recipientInput(type: RecipientType) -> RecipientEmailTextFieldNode {
        return RecipientEmailTextFieldNode(
            input: decorator.styledTextFieldInput(
                with: "",
                keyboardType: .emailAddress,
                accessibilityIdentifier: "aid-recipients-text-field-\(type.rawValue)",
                insets: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
            ),
            action: { [weak self] action in
                self?.handle(textFieldAction: action, for: type)
            }
        )
        .onShouldReturn { [weak self] textField -> (Bool) in
            if let isValid = self?.showAlertIfTextFieldNotValidEmail(textField: textField), isValid {
                textField.resignFirstResponder()
                return true
            }
            return false
        }
        .onShouldEndEditing { [weak self] textField -> (Bool) in
            if let isValid = self?.showAlertIfTextFieldNotValidEmail(textField: textField), isValid {
                return true
            }
            return false
        }
        .onShouldChangeCharacters { [weak self] textField, character -> (Bool) in
            self?.shouldChange(with: textField, and: character, for: type) ?? true
        }
        .then {
            if type == selectedRecipientType {
                $0.becomeFirstResponder()
            }
        }
    }

    internal func showAlertIfTextFieldNotValidEmail(textField: UITextField) -> Bool {
        if let text = textField.text, text.isEmpty || text.isValidEmail {
            return true
        }
        showAlert(title: "compose_invalid_recipient_title".localized, message: "compose_invalid_recipient_message".localized)
        return false
    }

    internal func attachmentNode(for index: Int) -> ASCellNode {
        AttachmentNode(
            input: .init(
                attachment: contextToSend.attachments[index],
                index: index
            ),
            onDeleteTap: { [weak self] in
                self?.contextToSend.attachments.safeRemove(at: index)
                self?.reload(sections: [.attachments])
            }
        )
    }

    internal func noSearchResultsNode() -> ASCellNode {
        TextCellNode(input: .init(
            backgroundColor: .clear,
            title: "compose_no_contacts_found".localized,
            withSpinner: false,
            size: .zero,
            insets: .deviceSpecificTextInsets(top: 16, bottom: 16),
            itemsAlignment: .start)
        )
    }

    internal func enableGoogleContactsNode() -> ASCellNode {
        TextWithIconNode(input: .init(
            title: "compose_enable_google_contacts_search"
                .localized
                .attributed(.regular(16)),
            image: UIImage(named: "gmail_icn"))
        )
    }
}
