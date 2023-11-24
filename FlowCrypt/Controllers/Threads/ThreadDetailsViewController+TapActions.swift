//
//  ThreadDetailsViewController+TapActions.swift
//  FlowCrypt
//
//  Created by Roma Sosnovsky on 01.11.2022
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import FlowCryptCommon
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
        Task {
            do {
                try await composeNewMessage(at: indexPath, quoteType: .reply)
            } catch {
                showAlert(message: error.errorMessage)
            }
        }
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

    func handleAttachmentTap(at indexPath: IndexPath) {
        Task {
            do {
                let attachment = try await getAttachment(at: indexPath)
                hideSpinner()

                if attachment.supportsPreview {
                    show(attachment: attachment)
                } else {
                    await attachmentManager.download(attachment)
                }
            } catch {
                handleAttachmentDecryptError(error, at: indexPath)
            }
        }
    }
}

// MARK: - Compsoe
extension ThreadDetailsViewController {
    private func fetchAttachmentDataIfNil(attachment: MessageAttachment, messageId: Identifier) async throws -> MessageAttachment {
        if attachment.data == nil {
            var updatedAttachment = attachment
            showSpinner()
            updatedAttachment.data = try await messageHelper.download(
                attachment: attachment,
                messageId: messageId,
                progressHandler: { [weak self] progress in
                    self?.handleFetchProgress(state: .download(progress))
                }
            )
            return updatedAttachment
        }
        return attachment
    }

    private func decrypt(attachment: MessageAttachment) async throws -> MessageAttachment {
        let trace = Trace(id: "Attachment")

        if attachment.isEncrypted {
            handleFetchProgress(state: .decrypt)
            logger.logInfo("Got encrypted attachment - \(trace.finish())")
            return try await messageHelper.decrypt(
                attachment: attachment,
                userEmail: appContext.user.email
            )
        }
        logger.logInfo("Attachment is not encrypted. Returning original attachment - \(trace.finish())")
        return attachment
    }

    // swiftlint:disable cyclomatic_complexity function_body_length
    private func composeNewMessage(at indexPath: IndexPath, quoteType: MessageQuoteType) async throws {
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
        let decryptedAttachments = try await attachments.asyncMap {
            let fetchedAttachment = try await fetchAttachmentDataIfNil(attachment: $0, messageId: input.rawMessage.identifier)
            return try await decrypt(attachment: fetchedAttachment)
        }
        hideSpinner()

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
            text: processedMessage.fullText.removingHtmlTags() ?? "",
            threadId: threadId,
            replyToMsgId: replyToMsgId,
            inReplyTo: input.rawMessage.inReplyTo,
            rfc822MsgId: input.rawMessage.rfc822MsgId,
            draftId: nil,
            shouldEncrypt: input.rawMessage.isPgp,
            attachments: decryptedAttachments
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

    // swiftlint:enable cyclomatic_complexity function_body_length

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
            Task {
                do {
                    try await self?.composeNewMessage(at: indexPath, quoteType: type)
                } catch {
                    self?.showAlert(message: error.errorMessage)
                }
            }
        }
        action.accessibilityIdentifier = type.accessibilityIdentifier
        return action
    }
}

// MARK: - Attachments
extension ThreadDetailsViewController {
    func getAttachment(at indexPath: IndexPath) async throws -> MessageAttachment {
        defer { node.reloadRows(at: [indexPath], with: .automatic) }

        let sectionIndex = indexPath.section - 1
        let section = input[sectionIndex]
        let attachmentIndex = indexPath.row - 2 - (section.processedMessage?.keyDetails.count ?? 0)

        guard let rawAttachment = section.processedMessage?.attachments[attachmentIndex] else {
            throw MessageHelperError.attachmentNotFound
        }

        let fetchedAttachment = try await fetchAttachmentDataIfNil(attachment: rawAttachment, messageId: section.rawMessage.identifier)
        input[sectionIndex].processedMessage?.attachments[attachmentIndex] = fetchedAttachment
        let decryptedAttachment = try await decrypt(attachment: fetchedAttachment)
        input[sectionIndex].processedMessage?.attachments[attachmentIndex] = decryptedAttachment
        return decryptedAttachment
    }

    func show(attachment: MessageAttachment) {
        navigationController?.pushViewController(
            AttachmentViewController(file: attachment),
            animated: true
        )
    }

    private func handleAttachmentDecryptError(_ error: Error, at indexPath: IndexPath) {
        let message = "message_attachment_corrupted_file".localized

        showAlertWithAction(
            title: "message_attachment_decrypt_error".localized,
            message: "\n\(error.errorMessage)\n\n\(message)",
            actionButtonTitle: "download".localized,
            actionAccessibilityIdentifier: "aid-download-button",
            onAction: { [weak self] _ in
                guard let attachment = self?.input[indexPath.section - 1].processedMessage?.attachments[indexPath.row - 2] else {
                    return
                }
                self?.show(attachment: attachment)
            }
        )
    }
}
