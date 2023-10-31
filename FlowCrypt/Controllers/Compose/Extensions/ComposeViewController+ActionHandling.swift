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
    func searchEmail(with query: String) {
        Task {
            do {
                let cloudRecipients = try await contactsProvider.searchContacts(query: query)
                let localRecipients = try localContactsProvider.searchRecipients(query: query)

                let recipients = (cloudRecipients + localRecipients).unique().sorted()
                updateView(newState: .searchEmails(recipients))
            } catch {
                showAlert(message: error.errorMessage)
            }
        }
    }

    func evaluate(recipient: ComposeMessageRecipient) {
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
                try await pubLookup.fetchRemoteUpdateLocal(with: contact)

                if let updatedContact = try await localContactsProvider.searchRecipient(with: recipient.email) {
                    handleEvaluation(for: updatedContact)
                }

                showRecipientLabelIfNecessary()
            } catch {
                handleEvaluation(error: error, with: recipient.email, contact: localContact)
                showRecipientLabelIfNecessary()
            }
        }
    }

    func handleEvaluation(for recipient: RecipientWithSortedPubKeys) {
        let state = getRecipientState(from: recipient)

        updateRecipient(
            email: recipient.email,
            name: recipient.name,
            state: state,
            keyState: recipient.keyState
        )
    }

    func getRecipientState(from recipient: RecipientWithSortedPubKeys) -> RecipientState {
        switch recipient.keyState {
        case .active:
            return decorator.recipientKeyFoundState
        case .expired:
            return decorator.recipientKeyExpiredState
        case .unUsableForEncryption:
            return decorator.recipientKeyUnUsuableForEncryptionState
        case .unUsableForSigning:
            return decorator.recipientKeyUnUsuableForSigningState
        case .revoked:
            return decorator.recipientKeyRevokedState
        case .empty:
            return decorator.recipientKeyNotFoundState
        }
    }

    func handleEvaluation(error: Error, with email: String, contact: RecipientWithSortedPubKeys?) {
        if let apiError = error as? ApiError, let nsError = apiError.internalError as NSError?, nsError.domain == NSURLErrorDomain {
            showAlert(message: error.localizedDescription)
        }
        let recipientState: RecipientState = {
            if let contact, contact.keyState == .active {
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

    func updateRecipient(
        email: String,
        name: String? = nil,
        state: RecipientState,
        keyState: PubKeyState? = nil
    ) {
        guard let index = contextToSend.recipients.firstIndex(where: { $0.email == email }) else {
            return
        }

        var displayName = name
        if let name, let address = MCOAddress(nonEncodedRFC822String: name), address.displayName != nil {
            displayName = address.displayName
        }

        let recipient = contextToSend.recipients[index]
        let needsReload = recipient.state != state || recipient.keyState != keyState || recipient.name != displayName

        contextToSend.recipients[index].state = state
        contextToSend.recipients[index].keyState = keyState

        if let displayName, displayName.isNotEmpty {
            contextToSend.recipients[index].name = displayName
        }

        if needsReload, selectedRecipientType == nil || selectedRecipientType == recipient.type {
            reload(sections: [.password])

            refreshRecipient(for: email, type: recipient.type, refreshType: .reload)
        }
    }

    func handleRecipientSelection(with indexPath: IndexPath, type: RecipientType) {
        guard var recipient = contextToSend.recipient(at: indexPath.row, type: type) else { return }

        recipient.state.isSelected.toggle()
        contextToSend.update(recipient: recipient.email, type: type, state: recipient.state)

        if !recipient.state.isSelected {
            evaluate(recipient: recipient)
        }

        refreshRecipient(for: recipient.email, type: type, refreshType: .reload)

        let textField = recipientsTextField(type: type)
        if !(textField?.isFirstResponder() ?? true) {
            textField?.becomeFirstResponder()
        }
        textField?.reset()
    }

    func handleRecipientAction(with indexPath: IndexPath, type: RecipientType) {
        guard let recipient = contextToSend.recipient(at: indexPath.row, type: type) else { return }

        switch recipient.state {
        case .idle:
            handleRecipientSelection(with: indexPath, type: type)
        case .keyFound, .keyExpired, .keyRevoked, .keyNotFound, .invalidEmail, .keyNotUsableForEncryption, .keyNotUsableForSigning:
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
    func setMessagePassword() {
        Task {
            stopDraftTimer(withSave: false)
            contextToSend.messagePassword = await enterMessagePassword()
            reload(sections: [.password])
            startDraftTimer()
        }
    }

    func enterMessagePassword() async -> String? {
        return await withCheckedContinuation { continuation in
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
            guard let self else { return }
            $0.isSecureTextEntry = true
            $0.text = self.contextToSend.messagePassword
            $0.accessibilityLabel = "aid-message-password-textfield"
            $0.addTarget(self, action: #selector(self.messagePasswordTextFieldDidChange), for: .editingChanged)
        }

        let cancelAction = UIAlertAction(title: "cancel".localized, style: .cancel) { [weak self] _ in
            return continuation.resume(returning: self?.contextToSend.messagePassword)
        }
        cancelAction.accessibilityIdentifier = "aid-cancel-button"
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
        let isPasswordStrong = composeMessageHelper.isMessagePasswordStrong(pwd: password)
        messagePasswordAlertController?.actions[1].isEnabled = isPasswordStrong
    }
}
