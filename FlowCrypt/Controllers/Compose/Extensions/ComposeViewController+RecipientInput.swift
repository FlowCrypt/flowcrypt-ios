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
        case .didPaste: return
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

        if !idleRecipients.contains(where: { $0.email == newRecipient.email }) {
            // add new recipient
            contextToSend.add(recipient: newRecipient)

            refreshRecipient(for: newRecipient.email, type: recipientType, refreshType: .add)
        }

        evaluate(recipient: newRecipient)

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.refreshRecipient(for: newRecipient.email, type: recipientType, refreshType: .scrollToBottom)
        }

        node.view.keyboardDismissMode = .interactive
        search.send("")

        updateView(newState: .main)
    }

    /// This function refreshes recipient cell.
    ///
    /// - Parameter email: Recipient email.
    /// - Parameter type: Recipient type.
    /// - Parameter refreshType: Refresh type (delete/add/reload/scrollToBottom).
    /// - Parameter TempRecipients: Temp recipients (Optional). Used to get deleted recipient index
    internal func refreshRecipient(
        for email: String,
        type: RecipientType,
        refreshType: RefreshType,
        tempRecipients: [ComposeMessageRecipient]? = nil
    ) {
        let recipients = tempRecipients ?? contextToSend.recipients(type: type)
        guard let indexPath = recipientsIndexPath(type: type),
           let emailNode = node.nodeForRow(at: indexPath) as? RecipientEmailsCellNode,
           let emailIndex = recipients.firstIndex(where: { $0.email == email && $0.type == type }) else {
            return
        }
        emailNode.setRecipientsInput(input: contextToSend.recipients(type: type).map(RecipientEmailsCellNode.Input.init))

        // Reload recipient section when there are no recipients left
        if refreshType == .delete && contextToSend.recipients(type: type).count < 1 {
            reload(sections: [.recipients(type)])
            return
        }

        let emailIndexPath = IndexPath(row: emailIndex, section: 0)
        switch refreshType {
        case .delete:
            emailNode.collectionNode.deleteItems(at: [emailIndexPath])
        case .reload:
            emailNode.collectionNode.reloadItems(at: [emailIndexPath])
        case .add:
            emailNode.collectionNode.insertItems(at: [emailIndexPath])
        case .scrollToBottom:
            emailNode.collectionNode.scrollToItem(at: emailIndexPath, at: .bottom, animated: true)
        }
    }

    internal func recipientsIndexPath(type: RecipientType) -> IndexPath? {
        guard let section = sectionsList.firstIndex(of: .recipients(type)) else { return nil }
        return IndexPath(row: 0, section: section)
    }

    internal func recipientsTextField(type: RecipientType) -> TextFieldNode? {
        guard let indexPath = recipientsIndexPath(type: type) else { return nil }
        return (node.nodeForRow(at: indexPath) as? RecipientEmailsCellNode)?.recipientInput.textField
    }

    internal func handleBackspaceAction(with textField: UITextField, for recipientType: RecipientType) {
        guard textField.text != "" else { return }

        var recipients = contextToSend.recipients(type: recipientType)

        let selectedRecipients = recipients.filter { $0.state.isSelected }

        guard selectedRecipients.isEmpty else {
            let tempRecipients = contextToSend.recipients(type: recipientType)
            let notSelectedRecipients = recipients.filter { !$0.state.isSelected }
            contextToSend.set(recipients: notSelectedRecipients, for: recipientType)
            reload(sections: [.password])

            refreshRecipient(for: selectedRecipients[0].email, type: recipientType, refreshType: .delete, tempRecipients: tempRecipients)

            hideRecipientPopOver()
            return
        }

        if var lastRecipient = recipients.popLast() {
            // select last recipient in a list
            lastRecipient.state = self.decorator.recipientSelectedState
            recipients.append(lastRecipient)
            contextToSend.set(recipients: recipients, for: recipientType)

            refreshRecipient(for: lastRecipient.email, type: recipientType, refreshType: .reload)
        } else {
            // dismiss keyboard if no recipients left
            textField.resignFirstResponder()
        }
    }

    internal func handleEditingChanged(with text: String?) {
        let inputText = text ?? ""
        shouldDisplaySearchResult = !inputText.isEmpty
        search.send(inputText)
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
