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

        let processedMessage = input[section - 1].processedMessage
        let attachmentsCount = processedMessage?.attachments.count ?? 0
        let pubkeysCount = processedMessage?.keyDetails.count ?? 0
        return Parts.allCases.count + attachmentsCount + pubkeysCount
    }

    // swiftlint:disable cyclomatic_complexity function_body_length
    func tableNode(_ tableNode: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        return { [weak self] in
            guard let self else { return ASCellNode() }

            let row = indexPath.row
            guard indexPath.section > 0 else {
                if row == 0 {
                    let subject = self.inboxItem.subject ?? "no subject"
                    return MessageSubjectNode(subject.attributed(.medium(18)))
                } else {
                    return self.dividerNode(indexPath: indexPath)
                }
            }

            let messageIndex = indexPath.section - 1
            let message = self.input[messageIndex]

            if !message.rawMessage.isDraft, row == 0 {
                return ThreadMessageInfoCellNode(
                    input: .init(threadMessage: message, index: messageIndex),
                    onReplyTap: { [weak self] _ in self?.handleReplyTap(at: indexPath) },
                    onMenuTap: { [weak self] _ in self?.handleMenuTap(at: indexPath) },
                    onRecipientsTap: { [weak self] _ in self?.handleRecipientsTap(at: indexPath) }
                )
            }

            if message.rawMessage.isDraft {
                if row == 0 {
                    return self.draftNode(messageIndex: messageIndex, isExpanded: message.isExpanded)
                } else {
                    return self.dividerNode(indexPath: indexPath)
                }
            }

            guard message.isExpanded, let processedMessage = message.processedMessage
            else { return self.dividerNode(indexPath: indexPath) }

            guard row > 1 else {
                if processedMessage.text.isHTMLString {
                    return ThreadDetailWebNode(
                        input: .init(message: processedMessage.text, quote: processedMessage.quote, index: messageIndex)
                    )
                }
                return MessageTextSubjectNode(
                    input: .init(
                        message: processedMessage.attributedMessage,
                        quote: processedMessage.attributedQuote,
                        index: messageIndex,
                        isEncrypted: processedMessage.type == .encrypted
                    )
                )
            }

            let keyCount = processedMessage.keyDetails.count
            let keyIndex = row - 2
            if keyIndex < keyCount {
                let keyDetails = processedMessage.keyDetails[keyIndex]
                let node = PublicKeyDetailNode(
                    input: Self.getPublicKeyDetailInput(for: keyDetails, localContactsProvider: localContactsProvider)
                )
                node.onImportKey = {
                    self.importPublicKey(indexPath: indexPath, keyDetails: keyDetails)
                }
                return node
            }

            let attachmentIndex = row - 2 - keyCount
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

    // swiftlint:enable cyclomatic_complexity function_body_length

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

    private func importPublicKey(indexPath: IndexPath, keyDetails: KeyDetails) {
        if let email = keyDetails.pgpUserEmails.first {
            try? localContactsProvider.updateKey(for: email, pubKey: .init(keyDetails: keyDetails))
            node.reloadRows(at: [indexPath], with: .automatic)
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

    static func getPublicKeyDetailInput(
        for keyDetails: KeyDetails,
        localContactsProvider: LocalContactsProviderType
    ) -> PublicKeyDetailNode.Input {
        let email = keyDetails.pgpUserEmails.first ?? "N/A"
        let localPublicKeys = (try? localContactsProvider.retrievePubKeys(for: email, shouldUpdateLastUsed: false)) ?? []
        let importStatus: PublicKeyDetailNode.PublicKeyImportStatus = {
            if localPublicKeys.contains(where: { keyDetails.fingerprints.contains($0.primaryFingerprint) }) {
                return .alreadyImported
            }
            return localPublicKeys.isNotEmpty ? .differentKeyImported : .notYetImported
        }()
        return PublicKeyDetailNode.Input(
            email: email,
            publicKey: keyDetails.public,
            fingerprint: keyDetails.fingerprints.first ?? "N/A",
            importStatus: importStatus
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

        return ThreadMessageDraftCellNode(sender: appContext.user.name, draftBody: body, messageIndex: messageIndex, action: {
            self.deleteDraft(id: data.rawMessage.identifier)
        })
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
                    try await self.messageOperationsApiClient.deleteMessage(
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
