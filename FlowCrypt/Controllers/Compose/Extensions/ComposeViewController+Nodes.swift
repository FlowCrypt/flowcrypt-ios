//
//  ComposeViewController+Nodes.swift
//  FlowCrypt
//
//  Created by Ioan Moldovan on 4/6/22
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import AsyncDisplayKit
import FlowCryptUI
import UIKit

// MARK: - Nodes
extension ComposeViewController {
    func recipientTextNode() -> ComposeRecipientCellNode {
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

    func showRecipientLabelIfNecessary() {
        let isRecipientLoading = contextToSend.recipients.contains(where: {
            $0.state == decorator.recipientIdleState
        })

        guard !isRecipientLoading,
              contextToSend.recipients.isNotEmpty,
              userTappedOutSideRecipientsArea,
              !shouldShowEmailRecipientsLabel
        else { return }

        shouldShowEmailRecipientsLabel = true
        userTappedOutSideRecipientsArea = false
        reload(sections: Section.recipientsSections + [.recipientsLabel])
    }

    func hideRecipientLabel() {
        shouldShowEmailRecipientsLabel = false
        reload(sections: Section.recipientsSections + [.recipientsLabel])
    }

    func setupSubjectNode() {
        composeSubjectNode = TextFieldCellNode(
            input: decorator.styledTextFieldInput(
                with: "compose_subject".localized,
                accessibilityIdentifier: "aid-subject-text-field"
            )
        ) { [weak self] event in
            switch event {
            case let .editingChanged(text), let .didEndEditing(text):
                self?.contextToSend.subject = text
            case .didBeginEditing:
                self?.userTappedOutSideRecipientsArea = true
                self?.showRecipientLabelIfNecessary()
            case .deleteBackward, .didPaste:
                return
            }
        }
        .onShouldReturn { [weak self] _ in
            guard let self else { return true }
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

    func fromCellNode() -> RecipientFromCellNode {
        RecipientFromCellNode(
            fromEmail: contextToSend.sender,
            toggleButtonAction: { [weak self] in
                self?.presentSendAsActionSheet()
            }
        )
    }

    private func presentSendAsActionSheet() {
        let alert = UIAlertController(
            title: nil,
            message: nil,
            preferredStyle: .actionSheet
        )

        let cancelAction = UIAlertAction(title: "cancel".localized, style: .cancel)
        cancelAction.accessibilityIdentifier = "aid-cancel-button"

        for aliasEmail in sendAsList {
            let action = UIAlertAction(
                title: aliasEmail.description,
                style: .default
            ) { [weak self] _ in
                self?.changeSendAs(to: aliasEmail.sendAsEmail)
            }
            // Remove @, . in email part as appium throws error for identifiers which contain @, .
            let emailIdentifier = aliasEmail.sendAsEmail
                .replacingOccurrences(of: "@", with: "-")
                .replacingOccurrences(of: ".", with: "-")
            action.accessibilityIdentifier = "aid-send-as-\(emailIdentifier)"
            alert.addAction(action)
        }
        alert.addAction(cancelAction)

        present(alert, animated: true, completion: nil)
    }

    private func changeSendAs(to email: String) {
        contextToSend.sender = email
        changeSignature()
        reload(sections: [.recipients(.from)])
    }

    private func changeSignature() {
        let pattern = "\\r?\\n\\r?\\n--\\r?\\n[\\s\\S]*"
        if let message = composeTextNode?.getText(),
           let signature = getSignature(),
           let regex = try? NSRegularExpression(pattern: pattern) {
            let range = NSRange(location: 0, length: message.utf16.count)
            let updatedSignature = regex.stringByReplacingMatches(in: message, options: [], range: range, withTemplate: signature)
            composeTextNode?.setText(text: updatedSignature)
        }
    }

    func messagePasswordNode() -> ASCellNode {
        let input = contextToSend.hasMessagePassword
            ? decorator.styledFilledMessagePasswordInput()
            : decorator.styledEmptyMessagePasswordInput()

        return MessageActionCellNode(
            input: input,
            action: { [weak self] in self?.setMessagePassword() }
        )
    }

    func getSignature() -> String? {
        let sendAs = sendAsList.first(where: { $0.sendAsEmail == contextToSend.sender })
        if let signature = sendAs?.signature, signature.isNotEmpty {
            return "\n\n--\n\(signature.removingHtmlTags())"
        }
        return nil
    }

    func setupTextNode() {
        let attributedString = decorator.styledMessage(with: contextToSend.message ?? "")
        let styledQuote = input.quotedText.attributed(.regular(17))

        let mutableString = NSMutableAttributedString(attributedString: attributedString)
        if input.isQuote, !mutableString.string.contains(styledQuote.string) {
            mutableString.append(styledQuote)
        }

        if let signatureRaw = getSignature() {
            let body = mutableString.string.replacingOccurrences(of: "\r\n", with: "\n")
                .replacingOccurrences(of: "\r", with: "\n")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            let signature = signatureRaw.replacingOccurrences(of: "\r\n", with: "\n")
                .replacingOccurrences(of: "\r", with: "\n")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            let alreadyEndsWithSig = body.contains(signature)
            if (!alreadyEndsWithSig) {
                mutableString.append(signatureRaw.attributed(.regular(17)))
            }
        }

        let height = max(decorator.frame(for: mutableString).height, 40)

        composeTextNode = TextViewCellNode(
            decorator.styledTextViewInput(
                with: height,
                accessibilityIdentifier: "aid-message-text-view"
            )
        ) { [weak self] event in
            guard let self else { return }
            switch event {
            case .didBeginEditing:
                self.userTappedOutSideRecipientsArea = true
                self.showRecipientLabelIfNecessary()
            case let .editingChanged(text), let .didEndEditing(text):
                self.contextToSend.message = text?.string
            case let .heightChanged(textView):
                self.ensureCursorVisible(textView: textView)
            }
        }
        .then { textNode in
            DispatchQueue.main.async {
                textNode.textView.scrollEnabled = false
                if !mutableString.string.isEmpty {
                    textNode.textView.attributedText = mutableString
                }

                // Set cursor position to start of text view
                let startIndex = textNode.textView.textView.beginningOfDocument
                textNode.textView.textView.selectedTextRange = textNode.textView.textView.textRange(
                    from: startIndex,
                    to: startIndex
                )

                if self.input.shouldFocusTextNode {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        textNode.becomeFirstResponder()
                    }
                }
            }
        }
    }

    func ensureCursorVisible(textView: UITextView) {
        guard let range = textView.selectedTextRange else { return }

        let cursorRect = textView.caretRect(for: range.start)

        var rectToMakeVisible = textView.convert(cursorRect, to: node.view)
        rectToMakeVisible.origin.y -= cursorRect.height
        rectToMakeVisible.size.height *= 3

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { // fix for animation lag
            self.node.view.scrollRectToVisible(rectToMakeVisible, animated: true)
        }
    }

    func recipientsNode(type: RecipientType) -> ASCellNode {
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
            } : nil
        )
        .onLayoutHeightChanged { [weak self] layoutHeight in
            self?.decorator.updateRecipientsNode(
                layoutHeight: layoutHeight,
                type: type,
                completion: {
                    if let indexPath = self?.recipientsIndexPath(type: type),
                       let emailsNode = self?.node.nodeForRow(at: indexPath) as? RecipientEmailsCellNode {
                        emailsNode.style.preferredSize.height = layoutHeight
                        emailsNode.setNeedsLayout()
                    }
                }
            )
        }
        .onItemSelect { [weak self] action in
            guard let self else { return }

            switch action {
            case let .imageTap(indexPath):
                self.handleRecipientAction(with: indexPath, type: type)
            case let .select(indexPath, sender):
                self.toggleRecipientTextField(isEnabled: false)
                self.handleRecipientSelection(with: indexPath, type: type)
                self.displayRecipientPopOver(with: indexPath, type: type, sender: sender)
            }
        }
    }

    func toggleRecipientTextField(isEnabled: Bool) {
        let types: [RecipientType] = [.to, .cc, .bcc]
        for type in types {
            self.recipientsTextField(type: type)?.isUserInteractionEnabled = isEnabled
        }
        if let type = selectedRecipientType, let textField = recipientsTextField(type: type) {
            textField.becomeFirstResponder()
        }
    }

    func recipientInput(type: RecipientType) -> RecipientEmailTextFieldNode {
        RecipientEmailTextFieldNode(
            input: decorator.styledTextFieldInput(
                with: "",
                keyboardType: .emailAddress,
                accessibilityIdentifier: "aid-recipients-text-field-\(type.rawValue)",
                insets: .zero
            ),
            action: { [weak self] action in
                self?.handle(textFieldAction: action, for: type)
            }
        )
        .onShouldReturn { [weak self] textField in
            guard let self else { return true }

            let isValid = self.showAlertIfTextFieldNotValidEmail(textField: textField)
            if isValid {
                textField.resignFirstResponder()
            }
            return isValid
        }
        .onShouldChangeCharacters { [weak self] textField, character in
            self?.shouldChange(with: textField, and: character, for: type) ?? true
        }
        .then {
            if type == selectedRecipientType {
                $0.becomeFirstResponder()
            }
        }
    }

    func showAlertIfTextFieldNotValidEmail(textField: UITextField) -> Bool {
        if let text = textField.text, text.isEmpty || text.isValidEmail {
            return true
        }
        showAlert(
            title: "compose_invalid_recipient_title".localized,
            message: "compose_invalid_recipient_message".localized
        )
        return false
    }

    func attachmentNode(for index: Int) -> ASCellNode {
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

    func noSearchResultsNode() -> ASCellNode {
        TextCellNode(input:
            .init(
                backgroundColor: .clear,
                title: "compose_no_contacts_found".localized,
                withSpinner: false,
                size: .zero,
                insets: .deviceSpecificTextInsets(top: 16, bottom: 16),
                itemsAlignment: .start
            )
        )
    }

    func enableGoogleContactsNode() -> ASCellNode {
        TextWithIconNode(input:
            .init(
                title: "compose_enable_google_contacts_search"
                    .localized
                    .attributed(.regular(16)),
                image: UIImage(named: "gmail_icn")
            )
        )
    }
}
