//
//  ThreadDetailsViewController.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 12.10.2021
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import AsyncDisplayKit
import FlowCryptUI
import FlowCryptCommon
import Foundation
import UIKit

final class ThreadDetailsViewController: TableNodeViewController {
    private lazy var logger = Logger.nested(Self.self)

    class Input {
        var rawMessage: Message
        var isExpanded: Bool
        var processedMessage: ProcessedMessage?

        init(message: Message, isExpanded: Bool) {
            self.rawMessage = message
            self.isExpanded = isExpanded
        }
    }

    private enum Parts: Int, CaseIterable {
        case thread, message
    }

    private let messageService: MessageService
    private let messageOperationsProvider: MessageOperationsProvider
    private let threadOperationsProvider: MessagesThreadOperationsProvider
    private let thread: MessageThread
    private let filesManager: FilesManagerType
    private var input: [ThreadDetailsViewController.Input]

    let trashFolderProvider: TrashFolderProviderType
    var currentFolderPath: String {
        thread.path
    }
    private let onComplete: MessageActionCompletion

    private lazy var attachmentManager = AttachmentManager(
        controller: self,
        filesManager: filesManager
    )

    init(
        messageService: MessageService = MessageService(),
        trashFolderProvider: TrashFolderProviderType = TrashFolderProvider(),
        messageOperationsProvider: MessageOperationsProvider = MailProvider.shared.messageOperationsProvider,
        threadOperationsProvider: MessagesThreadOperationsProvider,
        thread: MessageThread,
        filesManager: FilesManagerType = FilesManager(),
        completion: @escaping MessageActionCompletion
    ) {
        self.threadOperationsProvider = threadOperationsProvider
        self.messageService = messageService
        self.messageOperationsProvider = messageOperationsProvider
        self.trashFolderProvider = trashFolderProvider
        self.thread = thread
        self.filesManager = filesManager
        self.onComplete = completion
        self.input = thread.messages
            .sorted(by: { $0 > $1 })
            .map { Input(message: $0, isExpanded: false) }

        super.init(node: TableNode())
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        node.delegate = self
        node.dataSource = self

        setupNavigationBar()
        expandThreadMessage()
    }
}

extension ThreadDetailsViewController {
    private func expandThreadMessage() {
        let indexOfSectionToExpand = thread.messages.firstIndex(where: { $0.isMessageRead == false }) ?? input.count - 1
        let indexPath = IndexPath(row: 0, section: indexOfSectionToExpand + 1)
        handleTap(at: indexPath)
    }

    private func handleTap(at indexPath: IndexPath) {
        guard let threadNode = node.nodeForRow(at: indexPath) as? TextImageNode else {
            logger.logError("Fail to handle tap at \(indexPath)")
            return
        }

        UIView.animate(
            withDuration: 0.3,
            animations: {
                threadNode.imageNode.view.transform = CGAffineTransform(rotationAngle: .pi)
            },
            completion: { [weak self] _ in
                guard let self = self else {
                    return
                }

                if let processedMessage = self.input[indexPath.section-1].processedMessage {
                    self.handleReceived(message: processedMessage, at: indexPath)
                } else {
                    self.fetchDecryptAndRenderMsg(at: indexPath)
                }
            }
        )
    }

    private func markAsRead(at index: Int) {
        logger.logInfo("Mark message as read at \(index)")
        guard let message = input[safe: index]?.rawMessage else {
            return
        }

        Task {
            do {
                try await messageOperationsProvider.markAsRead(message: message, folder: currentFolderPath)
                let updatedMessage = input[index].rawMessage.markAsRead(true)
                input[index].rawMessage = updatedMessage
                node.reloadSections(IndexSet(integer: index), with: .fade)
            } catch {
                showToast("Could not mark message as read: \(error)")
            }
        }
    }
}

extension ThreadDetailsViewController {
    private func fetchDecryptAndRenderMsg(at indexPath: IndexPath) {
        let message = input[indexPath.section-1].rawMessage
        logger.logInfo("Start loading message")

        handleFetchProgress(state: .fetch)

        Task {
            do {
                let processedMessage = try await messageService.getAndProcessMessage(
                    with: message,
                    folder: thread.path,
                    progressHandler: { [weak self] in self?.handleFetchProgress(state: $0) }
                )
                handleReceived(message: processedMessage, at: indexPath)
            } catch {
                handleError(error, at: indexPath)
            }
        }
    }

    private func handleReceived(message processedMessage: ProcessedMessage, at indexPath: IndexPath) {
        hideSpinner()

        let messageIndex = indexPath.section - 1
        input[messageIndex].processedMessage = processedMessage
        input[messageIndex].isExpanded = !input[messageIndex].isExpanded
        markAsRead(at: messageIndex)

        UIView.animate(
            withDuration: 0.2,
            animations: {
                self.node.reloadSections(IndexSet(integer: indexPath.section), with: .fade)
            },
            completion: { _ in
                self.node.scrollToRow(at: indexPath, at: .middle, animated: true)
            })
    }

    private func handleError(_ error: Error, at indexPath: IndexPath) {
        logger.logInfo("Error \(error)")
        hideSpinner()

        switch error as? MessageServiceError {
        case let .missingPassPhrase(rawMimeData):
            handleMissedPassPhrase(for: rawMimeData, at: indexPath)
        case let .wrongPassPhrase(rawMimeData, passPhrase):
            handleWrongPathPhrase(for: rawMimeData, with: passPhrase, at: indexPath)
        default:
            // TODO: - Ticket - Improve error handling for MessageViewController
            if let someError = error as NSError?, someError.code == Imap.Err.fetch.rawValue {
                // todo - the missing msg should be removed from the list in inbox view
                // reproduce: 1) load inbox 2) move msg to trash on another email client 3) open trashed message in inbox
                showToast("Message not found in folder: \(thread.path)")
            } else {
                // todo - this should be a retry / cancel alert
                showAlert(error: error, message: "message_failed_open".localized + "\n\n\(error)")
            }
            navigationController?.popViewController(animated: true)
        }
    }

    private func handleMissedPassPhrase(for rawMimeData: Data, at indexPath: IndexPath) {
        let alert = AlertsFactory.makePassPhraseAlert(
            onCancel: { [weak self] in
                self?.navigationController?.popViewController(animated: true)
            },
            onCompletion: { [weak self] passPhrase in
                self?.handlePassPhraseEntry(rawMimeData: rawMimeData, with: passPhrase, at: indexPath)
            })

        present(alert, animated: true, completion: nil)
    }

    private func handleWrongPathPhrase(for rawMimeData: Data, with phrase: String, at indexPath: IndexPath) {
        let alert = AlertsFactory.makeWrongPassPhraseAlert(
            onCancel: { [weak self] in
                self?.navigationController?.popViewController(animated: true)
            },
            onCompletion: { [weak self] passPhrase in
                self?.handlePassPhraseEntry(rawMimeData: rawMimeData, with: passPhrase, at: indexPath)
            })
        present(alert, animated: true, completion: nil)
    }

    private func handlePassPhraseEntry(rawMimeData: Data, with passPhrase: String, at indexPath: IndexPath) {
        handleFetchProgress(state: .decrypt)

        Task {
            do {
                let matched = try await messageService.checkAndPotentiallySaveEnteredPassPhrase(passPhrase)
                if matched {
                    let processedMessage = try await messageService.decryptAndProcessMessage(mime: rawMimeData)
                    handleReceived(message: processedMessage, at: indexPath)
                } else {
                    handleWrongPathPhrase(for: rawMimeData, with: passPhrase, at: indexPath)
                }
            } catch {
                handleError(error, at: indexPath)
            }
        }
    }

    private func handleFetchProgress(state: MessageFetchState) {
        switch state {
        case .fetch:
            showSpinner("loading_title".localized, isUserInteractionEnabled: true)
        case .download(let progress):
            updateSpinner(label: "downloading_title".localized, progress: progress)
        case .decrypt:
            updateSpinner(label: "decrypting_title".localized)
        }
    }
}

extension ThreadDetailsViewController: MessageActionsHandler {
    private func handleSuccessfulMessage(action: MessageAction) {
        hideSpinner()
        onComplete(action, .init(thread: thread))
        navigationController?.popViewController(animated: true)
    }

    private func handleMessageAction(error: Error) {
        logger.logError("Error mark as read \(error)")
        hideSpinner()
    }

    func permanentlyDelete() {
        logger.logInfo("permanently delete")
        Task {
            do {
                showSpinner()
                try await threadOperationsProvider.delete(thread: thread)
                handleSuccessfulMessage(action: .permanentlyDelete)
            } catch {
                handleMessageAction(error: error)
            }
        }
    }

    func moveToTrash(with trashPath: String) {
        logger.logInfo("move to trash \(trashPath)")
        Task {
            do {
                showSpinner()
                try await threadOperationsProvider.moveThreadToTrash(thread: thread)
                handleSuccessfulMessage(action: .moveToTrash)
            } catch {
                handleMessageAction(error: error)
            }
        }
    }

    func handleArchiveTap() {
        Task {
            do {
                showSpinner()
                try await threadOperationsProvider.archive(thread: thread, in: currentFolderPath)
                handleSuccessfulMessage(action: .archive)
            } catch {
                handleMessageAction(error: error)
            }
        }
    }

    func handleMarkUnreadTap() {
        let messages = input.filter { $0.isExpanded }.map(\.rawMessage)

        guard messages.isNotEmpty else {
            return
        }

        Task {
            do {
                showSpinner()
                try await threadOperationsProvider.mark(thread: thread, asRead: false, in: currentFolderPath)
                handleSuccessfulMessage(action: .markAsRead(false))
            } catch {
                handleMessageAction(error: error)
            }
        }
    }
}

extension ThreadDetailsViewController: ASTableDelegate, ASTableDataSource {
    func numberOfSections(in tableNode: ASTableNode) -> Int {
        input.count + 1
    }

    func tableNode(_ tableNode: ASTableNode, numberOfRowsInSection section: Int) -> Int {
        guard section > 0, input[section-1].isExpanded else { return 1 }

        let count = input[section-1].processedMessage?.attachments.count ?? 0
        return Parts.allCases.count + count
    }

    func tableNode(_ tableNode: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        return { [weak self] in
            guard let self = self else { return ASCellNode() }

            guard indexPath.section > 0 else {
                let subject = self.thread.subject ?? "no subject"
                return MessageSubjectNode(subject.attributed(.medium(18)))
            }

            let section = self.input[indexPath.section-1]

            if indexPath.row == 0 {
                return TextImageNode(
                    input: .init(threadMessage: section),
                    onTap: { [weak self] _ in
                        self?.handleTap(at: indexPath)
                    }
                )
            }

            if indexPath.row == 1, let message = section.processedMessage {
                return MessageTextSubjectNode(message.attributedMessage)
            }

            if indexPath.row > 1, let message = section.processedMessage {
                let attachment = message.attachments[indexPath.row - 2]
                return AttachmentNode(
                    input: .init(
                        msgAttachment: attachment
                    ),
                    onDownloadTap: { [weak self] in self?.attachmentManager.open(attachment) }
                )
            }

            return ASCellNode()
        }
    }

    func tableNode(_ tableNode: ASTableNode, didSelectRowAt indexPath: IndexPath) {
        guard tableNode.nodeForRow(at: indexPath) is TextImageNode  else {
            return
        }
        handleTap(at: indexPath)
    }
}

extension ThreadDetailsViewController: NavigationChildController {
    func handleBackButtonTap() {
        let isRead = input.contains(where: { $0.rawMessage.isMessageRead })
        logger.logInfo("Back button. Are all messages read \(isRead) ")
        onComplete(MessageAction.markAsRead(isRead), .init(thread: thread))
        navigationController?.popViewController(animated: true)
    }
}
