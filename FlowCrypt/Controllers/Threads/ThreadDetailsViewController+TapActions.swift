//
//  ThreadDetailsViewController+TapActions.swift
//  FlowCrypt
//
//  Created by Roma Sosnovsky on 01.11.2022
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import FlowCryptUI
import UIKit

extension ThreadDetailsViewController {
    func handleExpandTap(at indexPath: IndexPath) {
        let index = indexPath.section - 1
        input[index].isExpanded.toggle()

        if input[index].isExpanded {
            UIView.animate(
                withDuration: 0.2,
                animations: {
                    if let threadNode = self.node.nodeForRow(at: indexPath) as? ThreadMessageInfoCellNode {
                        threadNode.expandNode.view.alpha = 0
                    }
                },
                completion: { [weak self] _ in
                    guard let self else { return }

                    if let processedMessage = self.input[index].processedMessage {
                        self.handle(processedMessage: processedMessage, at: indexPath)
                    } else {
                        self.fetchDecryptAndRenderMsg(at: indexPath)
                    }
                }
            )
        } else {
            UIView.animate(withDuration: 0.3) {
                self.node.reloadSections([indexPath.section], with: .automatic)
            }
        }
    }

    func handleRecipientsTap(at indexPath: IndexPath) {
        input[indexPath.section - 1].shouldShowRecipientsList.toggle()

        UIView.animate(withDuration: 0.3) {
            self.node.reloadSections([indexPath.section], with: .automatic)
        }
    }

    func handleReplyTap(at indexPath: IndexPath) {
        composeNewMessage(at: indexPath, quoteType: .reply)
    }

    func handleDraftTap(at indexPath: IndexPath) {
        Task {
            do {
                let draft = input[indexPath.section - 1]

                let draftInfo = ComposeMessageInput.MessageQuoteInfo(
                    message: draft.rawMessage,
                    processed: draft.processedMessage
                )

                let controller = try await ComposeViewController(
                    appContext: appContext,
                    input: .init(type: .draft(draftInfo)),
                    handleAction: { [weak self] action in
                        self?.handleComposeMessageAction(action)
                    }
                )
                navigationController?.pushViewController(controller, animated: true)
            } catch {
                showAlert(message: error.errorMessage)
            }
        }
    }

    func handleMenuTap(at indexPath: IndexPath) {
        let alert = UIAlertController(
            title: nil,
            message: nil,
            preferredStyle: .actionSheet
        )

        if let view = node.nodeForRow(at: indexPath) as? ThreadMessageInfoCellNode {
            alert.popoverPresentation(style: .sourceView(view.menuNode.view))
        } else {
            alert.popoverPresentation(style: .centred(view))
        }

        let cancelAction = UIAlertAction(title: "cancel".localized, style: .cancel)
        cancelAction.accessibilityIdentifier = "aid-cancel-button"

        alert.addAction(createComposeNewMessageAlertAction(at: indexPath, type: .replyAll))
        alert.addAction(createComposeNewMessageAlertAction(at: indexPath, type: .forward))
        alert.addAction(cancelAction)

        present(alert, animated: true, completion: nil)
    }
}

extension ThreadDetailsViewController {
    private func composeNewMessage(at indexPath: IndexPath, quoteType: MessageQuoteType) {
        guard let input = input[safe: indexPath.section - 1],
              let processedMessage = input.processedMessage
        else { return }

        let sender = [input.rawMessage.sender].compactMap { $0 }
        let replyRecipient: [Recipient] = {
            if input.rawMessage.replyTo.isNotEmpty {
                return input.rawMessage.replyTo
            }
            // When sender is logged in user, then use `to` as reply recipient
            if sender.contains(where: { $0.email == appContext.user.email }) {
                return input.rawMessage.to
            }
            return sender
        }()

        let ccRecipients = quoteType == .replyAll ? input.rawMessage.cc : []
        let recipients: [Recipient] = {
            switch quoteType {
            case .reply:
                return replyRecipient
            case .replyAll:
                let allRecipients = (input.rawMessage.to + replyRecipient).unique()
                let filteredRecipients = allRecipients.filter { $0.email != appContext.user.email }
                return filteredRecipients.isEmpty ? sender : filteredRecipients
            case .forward:
                return []
            }
        }()

        let attachments = quoteType == .forward
            ? input.processedMessage?.attachments ?? []
            : []

        let subject = input.rawMessage.subject ?? "(no subject)"
        let threadId = quoteType == .forward ? nil : input.rawMessage.threadId
        let replyToMsgId = quoteType == .forward ? nil : input.rawMessage.rfc822MsgId

        let replyInfo = ComposeMessageInput.MessageQuoteInfo(
            id: nil,
            recipients: recipients,
            ccRecipients: ccRecipients,
            bccRecipients: [],
            sender: input.rawMessage.sender,
            subject: [quoteType.subjectPrefix, subject].joined(),
            sentDate: input.rawMessage.date,
            text: processedMessage.text,
            threadId: threadId,
            replyToMsgId: replyToMsgId,
            inReplyTo: input.rawMessage.inReplyTo,
            rfc822MsgId: input.rawMessage.rfc822MsgId,
            draftId: nil,
            shouldEncrypt: input.rawMessage.isPgp,
            attachments: attachments
        )

        let composeType: ComposeMessageInput.InputType = {
            switch quoteType {
            case .reply, .replyAll:
                return .reply(replyInfo)
            case .forward:
                return .forward(replyInfo)
            }
        }()

        openComposeScreen(type: composeType)
    }

    private func openComposeScreen(type: ComposeMessageInput.InputType) {
        Task {
            do {
                let composeVC = try await ComposeViewController(
                    appContext: appContext,
                    input: ComposeMessageInput(type: type),
                    handleAction: { [weak self] action in
                        self?.handleComposeMessageAction(action)
                    }
                )
                navigationController?.pushViewController(composeVC, animated: true)
            } catch {
                showAlert(message: error.errorMessage)
            }
        }
    }

    private func createComposeNewMessageAlertAction(at indexPath: IndexPath, type: MessageQuoteType) -> UIAlertAction {
        let action = UIAlertAction(
            title: type.actionLabel,
            style: .default
        ) { [weak self] _ in
            self?.composeNewMessage(at: indexPath, quoteType: type)
        }
        action.accessibilityIdentifier = type.accessibilityIdentifier
        return action
    }
}
