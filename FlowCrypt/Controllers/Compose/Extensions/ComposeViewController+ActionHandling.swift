//
//  ComposeViewController+ActionHandling.swift
//  FlowCrypt
//
//  Created by Ioan Moldovan on 4/6/22
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import FlowCryptUI
import MailCore
import UIKit

// MARK: - Action Handling
extension ComposeViewController {
    internal func searchEmail(with query: String) {
        Task {
            do {
                let cloudRecipients = try await googleUserService.searchContacts(query: query)
                let localRecipients = try localContactsProvider.searchRecipients(query: query)

                let recipients = (cloudRecipients + localRecipients)
                                    .unique()
                                    .sorted()

                updateState(with: .searchEmails(recipients))
            } catch {
                showAlert(message: error.localizedDescription)
            }
        }
    }

    internal func evaluate(recipient: ComposeMessageRecipient) {
        guard recipient.email.isValidEmail else {
            updateRecipient(
                email: recipient.email,
                name: recipient.name,
                state: decorator.recipientInvalidEmailState
            )
            return
        }

        Task {
            var localContact: RecipientWithSortedPubKeys?
            do {
                if let contact = try await localContactsProvider.searchRecipient(with: recipient.email) {
                    localContact = contact
                    handleEvaluation(for: contact)
                }

                let contact = Recipient(recipient: recipient)
                let contactWithFetchedKeys = try await pubLookup.fetchRemoteUpdateLocal(with: contact)

                handleEvaluation(for: contactWithFetchedKeys)
                showRecipientLabelIfNecessary()
            } catch {
                handleEvaluation(error: error, with: recipient.email, contact: localContact)
                showRecipientLabelIfNecessary()
            }
        }
    }

    internal func handleEvaluation(for recipient: RecipientWithSortedPubKeys) {
        let state = getRecipientState(from: recipient)

        updateRecipient(
            email: recipient.email,
            name: recipient.name,
            state: state,
            keyState: recipient.keyState
        )
    }

    internal func getRecipientState(from recipient: RecipientWithSortedPubKeys) -> RecipientState {
        switch recipient.keyState {
        case .active:
            return decorator.recipientKeyFoundState
        case .expired:
            return decorator.recipientKeyExpiredState
        case .revoked:
            return decorator.recipientKeyRevokedState
        case .empty:
            return decorator.recipientKeyNotFoundState
        }
    }

    internal func handleEvaluation(error: Error, with email: String, contact: RecipientWithSortedPubKeys?) {
        let recipientState: RecipientState = {
            if let contact = contact, contact.keyState == .active {
                return getRecipientState(from: contact)
            }
            switch error {
            case ContactsError.keyMissing:
                return self.decorator.recipientKeyNotFoundState
            default:
                return self.decorator.recipientErrorStateRetry
            }
        }()

        updateRecipient(
            email: email,
            state: recipientState,
            keyState: nil
        )
    }

    internal func updateRecipient(
        email: String,
        name: String? = nil,
        state: RecipientState,
        keyState: PubKeyState? = nil
    ) {
        guard let index = contextToSend.recipients.firstIndex(where: { $0.email == email }) else {
            return
        }

        var displayName = name
        if let name = name, let address = MCOAddress.init(nonEncodedRFC822String: name), address.displayName != nil {
            displayName = address.displayName
        }

        let recipient = contextToSend.recipients[index]
        let needsReload = recipient.state != state || recipient.keyState != keyState || recipient.name != displayName

        contextToSend.recipients[index].state = state
        contextToSend.recipients[index].keyState = keyState
        if let displayName = displayName, displayName.isNotEmpty {
            contextToSend.recipients[index].name = displayName
        }

        if needsReload, selectedRecipientType == nil || selectedRecipientType == recipient.type {
            reload(sections: [.password])

            refreshRecipient(for: email, type: recipient.type, refreshType: .reload)
        }
    }

    internal func handleRecipientSelection(with indexPath: IndexPath, type: RecipientType) {
        guard let recipient = contextToSend.recipient(at: indexPath.row, type: type) else { return }

        let isSelected = recipient.state.isSelected
        let state = isSelected ? decorator.recipientIdleState : decorator.recipientSelectedState
        contextToSend.update(recipient: recipient.email, type: type, state: state)

        if isSelected {
            evaluate(recipient: recipient)
        }

        refreshRecipient(for: recipient.email, type: type, refreshType: .reload)

        let textField = recipientsTextField(type: type)
        if !(textField?.isFirstResponder() ?? true) {
            textField?.becomeFirstResponder()
        }
        textField?.reset()
    }

    internal func handleRecipientAction(with indexPath: IndexPath, type: RecipientType) {
        guard let recipient = contextToSend.recipient(at: indexPath.row, type: type) else { return }

        switch recipient.state {
        case .idle:
            handleRecipientSelection(with: indexPath, type: type)
        case .keyFound, .keyExpired, .keyRevoked, .keyNotFound, .invalidEmail, .selected:
            break
        case let .error(_, isRetryError):
            if isRetryError {
                updateRecipient(
                    email: recipient.email,
                    name: recipient.name,
                    state: decorator.recipientIdleState,
                    keyState: nil
                )
                evaluate(recipient: recipient)
            } else {
                let tempRecipients = contextToSend.recipients(type: type)
                contextToSend.remove(recipient: recipient.email, type: type)

                refreshRecipient(for: recipient.email, type: type, refreshType: .delete, tempRecipients: tempRecipients)
            }
        }
    }

    // MARK: - Message password
    internal func setMessagePassword() {
        Task {
            contextToSend.messagePassword = await enterMessagePassword()
            reload(sections: [.password])
        }
    }

    internal func enterMessagePassword() async -> String? {
        return await withCheckedContinuation { (continuation: CheckedContinuation<String?, Never>) in
            self.messagePasswordAlertController = createMessagePasswordAlert(continuation: continuation)
            self.present(self.messagePasswordAlertController!, animated: true, completion: nil)
        }
    }

    private func createMessagePasswordAlert(continuation: CheckedContinuation<String?, Never>) -> UIAlertController {
        let alert = UIAlertController(
            title: "compose_password_modal_title".localized,
            message: "compose_password_modal_message".localized,
            preferredStyle: .alert
        )

        alert.addTextField { [weak self] in
            guard let self = self else { return }
            $0.isSecureTextEntry = true
            $0.text = self.contextToSend.messagePassword
            $0.accessibilityLabel = "aid-message-password-textfield"
            $0.addTarget(self, action: #selector(self.messagePasswordTextFieldDidChange), for: .editingChanged)
        }

        let cancelAction = UIAlertAction(title: "cancel".localized, style: .cancel) { _ in
            return continuation.resume(returning: self.contextToSend.messagePassword)
        }
        alert.addAction(cancelAction)

        let setAction = UIAlertAction(title: "set".localized, style: .default) { _ in
            return continuation.resume(returning: alert.textFields?[0].text)
        }
        setAction.isEnabled = contextToSend.hasMessagePassword
        alert.addAction(setAction)

        return alert
    }

    @objc private func messagePasswordTextFieldDidChange(_ sender: UITextField) {
        let password = sender.text ?? ""
        let isPasswordStrong = composeMessageService.isMessagePasswordStrong(pwd: password)
        messagePasswordAlertController?.actions[1].isEnabled = isPasswordStrong
    }
}
