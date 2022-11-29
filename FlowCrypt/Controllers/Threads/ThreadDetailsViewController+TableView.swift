//
//  ThreadDetailsViewController+TableView.swift
//  FlowCrypt
//
//  Created by Roma Sosnovsky on 01.11.2022
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import AsyncDisplayKit
import FlowCryptUI
import Foundation

extension ThreadDetailsViewController: ASTableDelegate, ASTableDataSource {
    func numberOfSections(in tableNode: ASTableNode) -> Int {
        input.count + 1
    }

    func tableNode(_ tableNode: ASTableNode, numberOfRowsInSection section: Int) -> Int {
        guard section > 0, input[section - 1].isExpanded,
              !input[section - 1].rawMessage.isDraft
        else { return 2 }

        enum Parts: Int, CaseIterable {
            case thread, message, divider
        }

        let attachmentsCount = input[section - 1].processedMessage?.attachments.count ?? 0
        return Parts.allCases.count + attachmentsCount
    }

    func tableNode(_ tableNode: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        return { [weak self] in
            guard let self else { return ASCellNode() }

            guard indexPath.section > 0 else {
                if indexPath.row == 0 {
                    let subject = self.inboxItem.subject ?? "no subject"
                    return MessageSubjectNode(subject.attributed(.medium(18)))
                } else {
                    return self.dividerNode(indexPath: indexPath)
                }
            }

            let messageIndex = indexPath.section - 1
            let message = self.input[messageIndex]

            if !message.rawMessage.isDraft, indexPath.row == 0 {
                return ThreadMessageInfoCellNode(
                    input: .init(threadMessage: message, index: messageIndex),
                    onReplyTap: { [weak self] _ in self?.handleReplyTap(at: indexPath) },
                    onMenuTap: { [weak self] _ in self?.handleMenuTap(at: indexPath) },
                    onRecipientsTap: { [weak self] _ in self?.handleRecipientsTap(at: indexPath) }
                )
            }

            if message.rawMessage.isDraft {
                if indexPath.row == 0 {
                    return self.draftNode(messageIndex: messageIndex, isExpanded: message.isExpanded)
                } else {
                    return self.dividerNode(indexPath: indexPath)
                }
            }

            guard message.isExpanded, let processedMessage = message.processedMessage
            else { return self.dividerNode(indexPath: indexPath) }

            guard indexPath.row > 1 else {
                return MessageTextSubjectNode(
                    input: .init(
                        message: processedMessage.attributedMessage,
                        quote: processedMessage.attributedQuote,
                        index: messageIndex
                    )
                )
            }

            let attachmentIndex = indexPath.row - 2
            if let attachment = processedMessage.attachments[safe: attachmentIndex] {
                return AttachmentNode(
                    input: .init(
                        msgAttachment: attachment,
                        index: attachmentIndex
                    )
                )
            } else {
                return self.dividerNode(indexPath: indexPath)
            }
        }
    }

    func tableNode(_ tableNode: ASTableNode, didSelectRowAt indexPath: IndexPath) {
        switch tableNode.nodeForRow(at: indexPath) {
        case is ThreadMessageInfoCellNode:
            handleExpandTap(at: indexPath)
        case is AttachmentNode:
            handleAttachmentTap(at: indexPath)
        default:
            guard let message = input[safe: indexPath.section - 1],
                  message.rawMessage.isDraft
            else { return }

            handleDraftTap(at: indexPath)
        }
    }

    private func dividerNode(indexPath: IndexPath) -> ASCellNode {
        let height = indexPath.section < input.count ? 1 / UIScreen.main.nativeScale : 0
        return DividerCellNode(
            inset: .init(top: 0, left: 8, bottom: 0, right: 8),
            color: .borderColor,
            height: height
        )
    }
}

// MARK: - Drafts
extension ThreadDetailsViewController {
    private func draftNode(messageIndex: Int, isExpanded: Bool) -> ASCellNode {
        let data = input[messageIndex]

        let body: String
        if let processedMessage = data.processedMessage {
            body = processedMessage.text
        } else if data.rawMessage.isPgp {
            body = "Waiting for pass phrase to open draft..."
        } else {
            body = data.rawMessage.body.text
        }

        return LabelCellNode(
            input: .init(
                title: "draft".localized.attributed(color: .systemRed),
                text: body.removingMailThreadQuote().attributed(color: .secondaryLabel),
                accessibilityIdentifier: "aid-draft-body-\(messageIndex)",
                labelAccessibilityIdentifier: "aid-draft-label-\(messageIndex)",
                buttonAccessibilityIdentifier: "aid-draft-delete-button-\(messageIndex)",
                actionButtonImageName: "trash",
                action: { [weak self] in
                    self?.deleteDraft(id: data.rawMessage.identifier)
                }
            )
        )
    }

    private func deleteDraft(id: Identifier) {
        showAlertWithAction(
            title: "draft_delete_confirmation".localized,
            message: nil,
            actionButtonTitle: "delete".localized,
            actionStyle: .destructive,
            onAction: { [weak self] _ in
                guard let self else { return }

                Task {
                    try await self.messageOperationsProvider.deleteMessage(
                        id: id,
                        from: nil
                    )

                    let messageIdentifier = MessageIdentifier(
                        threadId: Identifier(stringId: self.inboxItem.threadId)
                    )
                    self.onComposeMessageAction?(.delete(messageIdentifier))

                    guard let index = self.input.firstIndex(where: { $0.rawMessage.identifier == id }) else { return }

                    self.input.remove(at: index)
                    self.node.deleteSections([index + 1], with: .automatic)
                }
            }
        )
    }
}
