//
//  ComposeViewController+RecipientPopup.swift
//  FlowCrypt
//
//  Created by Ioan Moldovan on 4/6/22
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import FlowCryptUI
import UIKit

extension ComposeViewController {
    func displayRecipientPopOver(with indexPath: IndexPath, type: RecipientType, sender: CellNode) {
        guard let recipient = contextToSend.recipient(at: indexPath.row, type: type) else { return }

        popoverVC = ComposeRecipientPopupViewController(
            recipient: recipient,
            type: type
        )
        popoverVC.modalPresentationStyle = .popover
        popoverVC.popoverPresentationController?.sourceView = sender.view
        popoverVC.popoverPresentationController?.permittedArrowDirections = .up
        popoverVC.popoverPresentationController?.delegate = self
        popoverVC.delegate = self
        present(popoverVC, animated: true, completion: nil)
    }

    func hideRecipientPopOver() {
        if popoverVC != nil {
            popoverVC.dismiss(animated: true, completion: nil)
        }
    }
}

extension ComposeViewController: UIPopoverPresentationControllerDelegate {
    public func adaptivePresentationStyle(
        for controller: UIPresentationController,
        traitCollection: UITraitCollection
    ) -> UIModalPresentationStyle {
        return .none
    }

    public func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        guard let popoverVC = presentationController.presentedViewController as? ComposeRecipientPopupViewController
        else { return }
        toggleRecipientTextField(isEnabled: true)
        deselectRecipients(type: popoverVC.type)
    }
}

extension ComposeViewController: ComposeRecipientPopupViewControllerProtocol {
    func removeRecipient(email: String, type: RecipientType) {
        let tempRecipients = contextToSend.recipients(type: type)
        contextToSend.remove(recipient: email, type: type)
        reload(sections: [.password])
        refreshRecipient(for: email, type: type, refreshType: .delete, tempRecipients: tempRecipients)
    }

    func editRecipient(email: String, type: RecipientType) {
        removeRecipient(email: email, type: type)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if let textField = self.recipientsTextField(type: type) {
                textField.text = email
                if !textField.isFirstResponder() {
                    textField.becomeFirstResponder()
                }
            }
        }
    }

    func enableRecipientEditing() {
        toggleRecipientTextField(isEnabled: true)
    }

    func deselectRecipients(type: RecipientType) {
        let recipients = contextToSend.recipients(type: type)
        let selectedRecipients = recipients.filter(\.state.isSelected)
        // Deselect previous selected receipients
        for recipient in selectedRecipients {
            var state = recipient.state
            state.isSelected.toggle()
            contextToSend.update(recipient: recipient.email, type: type, state: state)
            refreshRecipient(for: recipient.email, type: type, refreshType: .reload)
        }
    }
}
