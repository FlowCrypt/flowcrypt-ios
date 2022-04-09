//
//  ComposeViewController+RecipientInput.swift
//  FlowCrypt
//
//  Created by Ioan Moldovan on 4/6/22
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import UIKit
import FlowCryptUI

// MARK: - Recipients Input
extension ComposeViewController {
    internal func shouldChange(with textField: UITextField, and character: String, for recipientType: RecipientType) -> Bool {
        func nextResponder() {
            guard let node = node.visibleNodes[safe: ComposePart.subject.rawValue] as? TextFieldCellNode else { return }
            node.becomeFirstResponder()
        }

        guard let text = textField.text else { nextResponder(); return true }

        if text.isEmpty, character.count > 1 {
            // Pasted string
            let characterSet = CharacterSet(charactersIn: Constants.endTypingCharacters.joined())
            let recipients = character.components(separatedBy: characterSet)
            let validRecipients = recipients.filter { $0.isValidEmail }
            guard validRecipients.count > 1 else { return true }
            for recipient in validRecipients {
                handleEndEditingAction(with: recipient, for: recipientType)
            }
            return false
        } else if Constants.endTypingCharacters.contains(character),
                  self.showAlertIfTextFieldNotValidEmail(textField: textField) {
            handleEndEditingAction(with: textField.text, for: recipientType)
            nextResponder()
            return false
        }
        return true
    }

    internal func handle(textFieldAction: TextFieldActionType, for recipientType: RecipientType) {
        switch textFieldAction {
        case let .deleteBackward(textField): handleBackspaceAction(with: textField, for: recipientType)
        case let .didEndEditing(text): handleEndEditingAction(with: text, for: recipientType)
        case let .editingChanged(text): handleEditingChanged(with: text)
        case .didBeginEditing: handleDidBeginEditing(recipientType: recipientType)
        }
    }

    internal func handleEndEditingAction(with email: String?, name: String? = nil, for recipientType: RecipientType) {
        guard shouldEvaluateRecipientInput,
              let email = email, email.isNotEmpty
        else { return }

        let recipients = contextToSend.recipients(type: recipientType)

        let textField = recipientsTextField(type: recipientType)
        textField?.reset()

        // Set all selected recipients to idle state
        let idleRecipients: [ComposeMessageRecipient] = recipients.map { recipient in
            var recipient = recipient
            if recipient.state.isSelected {
                recipient.state = self.decorator.recipientIdleState
            }
            return recipient
        }

        contextToSend.set(recipients: idleRecipients, for: recipientType)

        let newRecipient = ComposeMessageRecipient(
            email: email,
            name: name,
            type: recipientType,
            state: decorator.recipientIdleState
        )

        let indexOfRecipient: Int

        let indexPath = recipientsIndexPath(type: recipientType, part: .list)

        if let index = idleRecipients.firstIndex(where: { $0.email == newRecipient.email }) {
            // recipient already in list
            evaluate(recipient: newRecipient)
            indexOfRecipient = index
        } else {
            // add new recipient
            contextToSend.add(recipient: newRecipient)

            if let indexPath = indexPath {
                node.reloadRows(at: [indexPath], with: .automatic)
            }

            evaluate(recipient: newRecipient)

            // scroll to the latest recipient
            indexOfRecipient = recipients.endIndex - 1
        }

        if let indexPath = indexPath,
           let emailsNode = node.nodeForRow(at: indexPath) as? RecipientEmailsCellNode {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                emailsNode.collectionNode.scrollToItem(
                    at: IndexPath(row: indexOfRecipient, section: 0),
                    at: .bottom,
                    animated: true
                )
            }
        }

        node.view.keyboardDismissMode = .interactive
        search.send("")

        updateState(with: .main)
    }

    internal func recipientsIndexPath(type: RecipientType, part: RecipientPart) -> IndexPath? {
        guard let section = sectionsList.firstIndex(of: .recipients(type)) else { return nil }
        return IndexPath(row: part.rawValue, section: section)
    }

    internal func recipientsTextField(type: RecipientType) -> TextFieldNode? {
        guard let indexPath = recipientsIndexPath(type: type, part: .input) else { return nil }
        return (node.nodeForRow(at: indexPath) as? RecipientEmailTextFieldNode)?.textField
    }

    internal func handleBackspaceAction(with textField: UITextField, for recipientType: RecipientType) {
        guard textField.text == "" else { return }

        var recipients = contextToSend.recipients(type: recipientType)

        let selectedRecipients = recipients.filter { $0.state.isSelected }

        guard selectedRecipients.isEmpty else {
            let notSelectedRecipients = recipients.filter { !$0.state.isSelected }
            contextToSend.set(recipients: notSelectedRecipients, for: recipientType)
            reload(sections: [.recipients(.to), .password])

            if let indexPath = recipientsIndexPath(type: recipientType, part: .list),
               let inputIndexPath = recipientsIndexPath(type: recipientType, part: .input) {
                node.reloadRows(at: [indexPath, inputIndexPath], with: .automatic)
            }

            hideRecipientPopOver()
            return
        }

        if var lastRecipient = recipients.popLast() {
            // select last recipient in a list
            lastRecipient.state = self.decorator.recipientSelectedState
            recipients.append(lastRecipient)
            contextToSend.set(recipients: recipients, for: recipientType)

            if let indexPath = recipientsIndexPath(type: recipientType, part: .list) {
                node.reloadRows(at: [indexPath], with: .automatic)
            }
        } else {
            // dismiss keyboard if no recipients left
            textField.resignFirstResponder()
        }
    }

    internal func handleEditingChanged(with text: String?) {
        shouldDisplaySearchResult = text != ""
        search.send(text ?? "")
    }

    internal func handleDidBeginEditing(recipientType: RecipientType) {
        selectedRecipientType = recipientType
        node.view.keyboardDismissMode = .none
    }

    internal func toggleRecipientsList() {
        shouldShowAllRecipientTypes.toggle()
        reload(sections: [.recipients(.cc), .recipients(.bcc)])
    }
}
