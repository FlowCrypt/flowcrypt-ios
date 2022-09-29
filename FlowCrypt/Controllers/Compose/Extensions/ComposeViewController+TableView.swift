//
//  ComposeViewController+TableView.swift
//  FlowCrypt
//
//  Created by Ioan Moldovan on 4/6/22
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import UIKit
import FlowCryptUI
import AsyncDisplayKit

// MARK: - ASTableDelegate, ASTableDataSource
extension ComposeViewController: ASTableDelegate, ASTableDataSource {
    func numberOfSections(in _: ASTableNode) -> Int {
        sectionsList.count
    }

    func tableNode(_: ASTableNode, numberOfRowsInSection section: Int) -> Int {
        guard let sectionItem = sectionsList[safe: section] else { return 0 }

        switch (state, sectionItem) {
        case (.main, .recipientsLabel):
            return shouldShowEmailRecipientsLabel ? 1 : 0
        case (.main, .recipients(.to)):
            return shouldShowEmailRecipientsLabel ? 0 : 1
        case (.main, .recipients(.from)):
            return !shouldShowEmailRecipientsLabel && sendAsList.count > 1 ? 1 : 0
        case (.main, .recipients(.cc)), (.main, .recipients(.bcc)):
            return !shouldShowEmailRecipientsLabel && shouldShowAllRecipientTypes ? 1 : 0
        case (.main, .password):
            return isMessagePasswordSupported && contextToSend.hasRecipientsWithoutPubKey ? 1 : 0
        case (.main, .compose):
            return ComposePart.allCases.count
        case (.main, .attachments):
            return contextToSend.attachments.count
        case (.searchEmails, .recipients(let type)):
            return selectedRecipientType == type ? 1 : 0
        case let (.searchEmails(emails), .searchResults):
            return emails.isNotEmpty ? emails.count + 1 : 2
        case (.searchEmails, .contacts):
            return googleUserService.isContactsScopeEnabled ? 0 : 2
        default:
            return 0
        }
    }

    // swiftlint:disable cyclomatic_complexity
    func tableNode(_ tableNode: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        return { [weak self] in
            guard let self = self,
                  let section = self.sectionsList[safe: indexPath.section]
            else { return ASCellNode() }

            switch (self.state, section) {
            case (_, .recipients(.from)):
                return self.fromCellNode()
            case (_, .recipients(.to)), (_, .recipients(.cc)), (_, .recipients(.bcc)):
                let recipientType = RecipientType.allCases[indexPath.section - 1]
                return self.recipientsNode(type: recipientType)
            case (.main, .recipientsLabel):
                return self.recipientTextNode()
            case (.main, .password):
                return self.messagePasswordNode()
            case (.main, .compose):
                guard let part = ComposePart(rawValue: indexPath.row) else { return ASCellNode() }
                switch part {
                case .subject: return self.composeSubjectNode ?? ASCellNode()
                case .text: return self.composeTextNode ?? ASCellNode()
                case .topDivider, .subjectDivider: return DividerCellNode()
                }
            case (.main, .attachments):
                guard !self.contextToSend.attachments.isEmpty else {
                    return ASCellNode()
                }
                return self.attachmentNode(for: indexPath.row)
            case let (.searchEmails(recipients), .searchResults):
                guard indexPath.row > 0 else { return DividerCellNode() }
                guard recipients.isNotEmpty else { return self.noSearchResultsNode() }
                guard let recipient = recipients[safe: indexPath.row - 1] else { return ASCellNode() }

                if let name = recipient.name {
                    let input = self.decorator.styledRecipientInfo(
                        with: recipient.email,
                        name: name
                    )
                    return LabelCellNode(input: input)
                } else {
                    let input = self.decorator.styledRecipientInfo(with: recipient.email)
                    return InfoCellNode(input: input)
                }
            case (.searchEmails, .contacts):
                return indexPath.row == 0 ? DividerCellNode() : self.enableGoogleContactsNode()
            default:
                return ASCellNode()
            }
        }
    }

    func tableNode(_ tableNode: ASTableNode, didSelectRowAt indexPath: IndexPath) {
        if case let .searchEmails(recipients) = state, let recipientType = selectedRecipientType {
            guard let section = sectionsList[safe: indexPath.section] else { return }

            switch section {
            case .searchResults:
                let recipient = recipients[safe: indexPath.row - 1]
                handleEndEditingAction(with: recipient?.email, name: recipient?.name, for: recipientType)
            case .contacts:
                askForContactsPermission()
            default:
                break
            }
        } else if tableNode.nodeForRow(at: indexPath) is AttachmentNode {
            let controller = AttachmentViewController(
                file: contextToSend.attachments[indexPath.row],
                shouldShowDownloadButton: false
            )
            navigationController?.pushViewController(controller, animated: true)
        }
    }

    func reload(sections: [Section]) {
        let indexes = sectionsList.enumerated().compactMap { index, section in
            sections.contains(section) ? index : nil
        }

        node.reloadSections(IndexSet(indexes), with: .automatic)
    }
}
