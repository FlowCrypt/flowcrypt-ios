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
        var shouldShowRecipientsList: Bool
        var processedMessage: ProcessedMessage?

        init(message: Message, isExpanded: Bool = false, shouldShowRecipientsList: Bool = false) {
            self.rawMessage = message
            self.isExpanded = isExpanded
            self.shouldShowRecipientsList = shouldShowRecipientsList
        }
    }

    private enum Parts: Int, CaseIterable {
        case thread, message
    }

    private let appContext: AppContextWithUser
    private let messageService: MessageService
    private let messageOperationsProvider: MessageOperationsProvider
    private let threadOperationsProvider: MessagesThreadOperationsProvider
    private let thread: MessageThread
    private var input: [ThreadDetailsViewController.Input]

    let trashFolderProvider: TrashFolderProviderType
    var currentFolderPath: String {
        thread.path
    }
    private let onComplete: MessageActionCompletion

    init(
        appContext: AppContextWithUser,
        messageService: MessageService? = nil,
        thread: MessageThread,
        completion: @escaping MessageActionCompletion
    ) {
        self.appContext = appContext
        let clientConfiguration = appContext.clientConfigurationService.getSaved(for: appContext.user.email)
        self.messageService = messageService ?? MessageService(
            contactsService: ContactsService(
                localContactsProvider: LocalContactsProvider(
                    encryptedStorage: appContext.encryptedStorage
                ),
                clientConfiguration: clientConfiguration
            ),
            keyService: appContext.keyService,
            messageProvider: appContext.getRequiredMailProvider().messageProvider,
            passPhraseService: appContext.passPhraseService
        )
        guard let threadOperationsProvider = appContext.getRequiredMailProvider().threadOperationsProvider else {
            fatalError("expected threadOperationsProvider on gmail")
        }
        self.threadOperationsProvider = threadOperationsProvider
        self.messageOperationsProvider = appContext.getRequiredMailProvider().messageOperationsProvider
        self.trashFolderProvider = TrashFolderProvider(
            user: appContext.user,
            foldersService: FoldersService(
                encryptedStorage: appContext.encryptedStorage,
                remoteFoldersProvider: appContext.getRequiredMailProvider().remoteFoldersProvider
            )
        )
        self.thread = thread
        self.onComplete = completion
        self.input = thread.messages
            .sorted(by: >)
            .map { Input(message: $0) }

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

        setupNavigationBar(user: appContext.user)
        expandThreadMessage()
    }
}

extension ThreadDetailsViewController {
    private func expandThreadMessage() {
        let indexOfSectionToExpand = thread.messages.firstIndex(where: { $0.isMessageRead == false }) ?? input.count - 1
        let indexPath = IndexPath(row: 0, section: indexOfSectionToExpand + 1)
        handleExpandTap(at: indexPath)
    }

    private func handleExpandTap(at indexPath: IndexPath) {
        guard let threadNode = node.nodeForRow(at: indexPath) as? ThreadMessageInfoCellNode else {
            logger.logError("Fail to handle tap at \(indexPath)")
            return
        }

        input[indexPath.section - 1].isExpanded.toggle()

        if input[indexPath.section-1].isExpanded {
            UIView.animate(
                withDuration: 0.3,
                animations: {
                    threadNode.expandNode.view.alpha = 0
                },
                completion: { [weak self] _ in
                    guard let self = self else { return }

                    if let processedMessage = self.input[indexPath.section-1].processedMessage {
                        self.handleReceived(message: processedMessage, at: indexPath)
                    } else {
                        self.fetchDecryptAndRenderMsg(at: indexPath)
                    }
                }
            )
        } else {
            UIView.animate(withDuration: 0.3) {
                self.node.reloadSections(IndexSet(integer: indexPath.section), with: .automatic)
            }
        }
    }

    private func handleRecipientsTap(at indexPath: IndexPath) {
        input[indexPath.section - 1].shouldShowRecipientsList.toggle()

        UIView.animate(withDuration: 0.3) {
            self.node.reloadSections(IndexSet(integer: indexPath.section), with: .automatic)
        }
    }

    private func handleReplyTap(at indexPath: IndexPath) {
        composeNewMessage(at: indexPath, quoteType: .reply)
    }

    private func handleMenuTap(at indexPath: IndexPath) {
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

        let replyAllAction = createMessageAlertAction(at: indexPath, type: .replyAll)
        let forwardAction = createMessageAlertAction(at: indexPath, type: .forward)
        let cancelAction = UIAlertAction(title: "cancel".localized, style: .cancel)
        [replyAllAction, forwardAction, cancelAction].forEach(alert.addAction)

        present(alert, animated: true, completion: nil)
    }

    private func createMessageAlertAction(at indexPath: IndexPath, type: MessageQuoteType) -> UIAlertAction {
        UIAlertAction(
            title: type.actionLabel,
            style: .default) { [weak self] _ in
                self?.composeNewMessage(at: indexPath, quoteType: type)
            }
    }

    private func handleAttachmentTap(at indexPath: IndexPath) {
        Task {
            do {
                let attachment = try await getAttachment(at: indexPath)
                show(attachment: attachment)
            } catch {
                handleAttachmentDecryptError(error, at: indexPath)
            }
        }
    }

    private func getAttachment(at indexPath: IndexPath) async throws -> MessageAttachment {
        let section = input[indexPath.section-1]
        let attachmentIndex = indexPath.row - 2

        guard let attachment = section.processedMessage?.attachments[attachmentIndex]
        else { throw MessageServiceError.attachmentNotFound }

        if attachment.isEncrypted {
            let decryptedAttachment = try await messageService.decrypt(attachment: attachment)
            input[indexPath.section-1].processedMessage?.attachments[attachmentIndex] = decryptedAttachment
            node.reloadRows(at: [indexPath], with: .automatic)
            return decryptedAttachment
        } else {
            return attachment
        }
    }

    private func show(attachment: MessageAttachment) {
        let attachmentViewController = AttachmentViewController(file: attachment)
        navigationController?.pushViewController(attachmentViewController, animated: true)
    }

    private func composeNewMessage(at indexPath: IndexPath, quoteType: MessageQuoteType) {
        guard let input = input[safe: indexPath.section-1],
              let processedMessage = input.processedMessage
        else { return }

        let recipients: [String] = {
            switch quoteType {
            case .reply:
                return [input.rawMessage.sender].compactMap({ $0 })
            case .replyAll:
                let recipientEmails = input.rawMessage.recipients.map(\.email)
                let allRecipients = recipientEmails + [input.rawMessage.sender].compactMap({ $0 })
                return allRecipients.filter { $0 != appContext.user.email }
            case .forward:
                return []
            }
        }()

        let attachments = quoteType == .forward
            ? input.processedMessage?.attachments ?? []
            : []

        let subject = input.rawMessage.subject ?? "(no subject)"
        let threadId = quoteType == .forward ? nil : input.rawMessage.threadId

        let replyInfo = ComposeMessageInput.MessageQuoteInfo(
            recipients: recipients,
            sender: input.rawMessage.sender,
            subject: [quoteType.subjectPrefix, subject].joined(),
            mime: processedMessage.rawMimeData,
            sentDate: input.rawMessage.date,
            message: processedMessage.text,
            threadId: threadId,
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

        let composeInput = ComposeMessageInput(type: composeType)
        navigationController?.pushViewController(
            ComposeViewController(appContext: appContext, input: composeInput),
            animated: true
        )
    }

    private func markAsRead(at index: Int) {
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
                showToast("message_mark_read_error".localizeWithArguments(error.localizedDescription))
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
                var processedMessage = try await messageService.getAndProcessMessage(
                    with: message,
                    folder: thread.path,
                    onlyLocalKeys: true,
                    progressHandler: { [weak self] in self?.handleFetchProgress(state: $0) }
                )
                if case .missingPubkey = processedMessage.signature {
                    processedMessage.signature = .pending
                    retryVerifyingSignatureWithRemotelyFetchedKeys(
                        message: message,
                        folder: thread.path,
                        indexPath: indexPath
                    )
                }
                handleReceived(message: processedMessage, at: indexPath)
            } catch {
                handleError(error, at: indexPath)
            }
        }
    }

    private func handleReceived(message processedMessage: ProcessedMessage, at indexPath: IndexPath) {
        hideSpinner()

        let messageIndex = indexPath.section - 1
        let isAlreadyProcessed = input[messageIndex].processedMessage != nil

        if !isAlreadyProcessed {
            input[messageIndex].processedMessage = processedMessage
            input[messageIndex].isExpanded = true

            markAsRead(at: messageIndex)

            UIView.animate(
                withDuration: 0.2,
                animations: {
                    self.node.reloadSections(IndexSet(integer: indexPath.section), with: .fade)
                },
                completion: { [weak self] _ in
                    self?.node.scrollToRow(at: indexPath, at: .middle, animated: true)
                })
        } else {
            input[messageIndex].processedMessage?.signature = processedMessage.signature
            node.reloadSections(IndexSet(integer: indexPath.section), with: .fade)
        }
    }

    private func handleError(_ error: Error, at indexPath: IndexPath) {
        logger.logInfo("Error \(error)")
        hideSpinner()

        switch error as? MessageServiceError {
        case let .missingPassPhrase(rawMimeData):
            handleMissedPassPhrase(for: rawMimeData, at: indexPath)
        case let .wrongPassPhrase(rawMimeData, passPhrase):
            handleWrongPassPhrase(for: rawMimeData, with: passPhrase, at: indexPath)
        default:
            // TODO: - Ticket - Improve error handling for ThreadDetailsViewController
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

    private func handleAttachmentDecryptError(_ error: Error, at indexPath: IndexPath) {
        let message = "message_attachment_corrupted_file".localized

        let alertController = UIAlertController(
            title: "message_attachment_decrypt_error".localized,
            message: "\n\(error.errorMessage)\n\n\(message)",
            preferredStyle: .alert
        )

        let downloadAction = UIAlertAction(title: "download".localized, style: .default) { [weak self] _ in
            guard let self = self,
                  let attachment = self.input[indexPath.section-1].processedMessage?.attachments[indexPath.row-2]
            else { return }

            self.show(attachment: attachment)
        }
        let cancelAction = UIAlertAction(title: "cancel".localized, style: .cancel)

        alertController.addAction(downloadAction)
        alertController.addAction(cancelAction)

        present(alertController, animated: true)
    }

    private func handleMissedPassPhrase(for rawMimeData: Data, at indexPath: IndexPath) {
        let alert = AlertsFactory.makePassPhraseAlert(
            onCancel: { [weak self] in
                self?.navigationController?.popViewController(animated: true)
            },
            onCompletion: { [weak self] passPhrase in
                self?.handlePassPhraseEntry(rawMimeData: rawMimeData, with: passPhrase, at: indexPath)
            }
        )

        present(alert, animated: true, completion: nil)
    }

    private func handleWrongPassPhrase(for rawMimeData: Data, with phrase: String, at indexPath: IndexPath) {
        let alert = AlertsFactory.makePassPhraseAlert(
            title: "setup_wrong_pass_phrase_retry".localized,
            onCancel: { [weak self] in
                self?.navigationController?.popViewController(animated: true)
            },
            onCompletion: { [weak self] passPhrase in
                self?.handlePassPhraseEntry(rawMimeData: rawMimeData, with: passPhrase, at: indexPath)
            }
        )
        present(alert, animated: true, completion: nil)
    }

    private func handlePassPhraseEntry(rawMimeData: Data, with passPhrase: String, at indexPath: IndexPath) {
        handleFetchProgress(state: .decrypt)

        Task {
            do {
                let matched = try await messageService.checkAndPotentiallySaveEnteredPassPhrase(passPhrase)
                if matched {
                    let sender = input[indexPath.section-1].rawMessage.sender
                    let processedMessage = try await messageService.decryptAndProcessMessage(
                        mime: rawMimeData,
                        sender: sender,
                        onlyLocalKeys: false
                    )
                    handleReceived(message: processedMessage, at: indexPath)
                } else {
                    handleWrongPassPhrase(for: rawMimeData, with: passPhrase, at: indexPath)
                }
            } catch {
                handleError(error, at: indexPath)
            }
        }
    }

    private func retryVerifyingSignatureWithRemotelyFetchedKeys(message: Message,
                                                                folder: String,
                                                                indexPath: IndexPath) {
        Task {
            do {
                let processedMessage = try await messageService.getAndProcessMessage(
                    with: message,
                    folder: thread.path,
                    onlyLocalKeys: false,
                    progressHandler: { _ in }
                )
                handleReceived(message: processedMessage, at: indexPath)
            } catch {
                let message = "message_signature_fail_reason".localizeWithArguments(error.errorMessage)
                input[indexPath.section-1].processedMessage?.signature = .error(message)
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
            updateSpinner(label: "processing_title".localized)
        }
    }
}

extension ThreadDetailsViewController: MessageActionsHandler {

    private func handleSuccessfulMessage(action: MessageAction) {
        hideSpinner()
        onComplete(action, .init(thread: thread, folderPath: currentFolderPath, activeUserEmail: appContext.user.email))
        navigationController?.popViewController(animated: true)
    }

    private func handleMessageAction(error: Error) {
        logger.logError("Error mark as read \(error)")
        hideSpinner()
    }

    func permanentlyDelete() {
        logger.logInfo("permanently delete")
        handle(action: .permanentlyDelete)
    }

    func moveToTrash(with trashPath: String) {
        logger.logInfo("move to trash \(trashPath)")
        handle(action: .moveToTrash)
    }

    func handleArchiveTap() {
        handle(action: .archive)
    }

    func handleMarkUnreadTap() {
        let messages = input.filter(\.isExpanded).map(\.rawMessage)

        guard messages.isNotEmpty else { return }

        handle(action: .markAsRead(false))
    }

    func handle(action: MessageAction) {
        Task {
            do {
                showSpinner()

                switch action {
                case .archive:
                    try await threadOperationsProvider.archive(thread: thread, in: currentFolderPath)
                case .markAsRead(let isRead):
                    guard !isRead else { return }
                    try await threadOperationsProvider.mark(thread: thread, asRead: false, in: currentFolderPath)
                case .moveToTrash:
                    try await threadOperationsProvider.moveThreadToTrash(thread: thread)
                case .permanentlyDelete:
                    try await threadOperationsProvider.delete(thread: thread)
                }

                handleSuccessfulMessage(action: action)
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

        let attachmentsCount = input[section-1].processedMessage?.attachments.count ?? 0
        return Parts.allCases.count + attachmentsCount
    }

    func tableNode(_ tableNode: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        return { [weak self] in
            guard let self = self else { return ASCellNode() }

            guard indexPath.section > 0 else {
                let subject = self.thread.subject ?? "no subject"
                return MessageSubjectNode(subject.attributed(.medium(18)))
            }

            let message = self.input[indexPath.section - 1]

            if indexPath.row == 0 {
                return ThreadMessageInfoCellNode(
                    input: .init(threadMessage: message),
                    onReplyTap: { [weak self] _ in self?.handleReplyTap(at: indexPath) },
                    onMenuTap: { [weak self] _ in self?.handleMenuTap(at: indexPath) },
                    onRecipientsTap: { [weak self] _ in self?.handleRecipientsTap(at: indexPath) }
                )
            }

            guard let processedMessage = message.processedMessage else {
                return ASCellNode()
            }

            guard indexPath.row > 1 else {
                return MessageTextSubjectNode(processedMessage.attributedMessage)
            }

            let attachmentIndex = indexPath.row - 2
            let attachment = processedMessage.attachments[attachmentIndex]
            return AttachmentNode(
                input: .init(
                    msgAttachment: attachment,
                    index: attachmentIndex
                )
            )
        }
    }

    func tableNode(_ tableNode: ASTableNode, didSelectRowAt indexPath: IndexPath) {
        switch tableNode.nodeForRow(at: indexPath) {
        case is ThreadMessageInfoCellNode:
            handleExpandTap(at: indexPath)
        case is AttachmentNode:
            handleAttachmentTap(at: indexPath)
        default: return
        }
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        dividerView()
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        section > 0 && section < input.count ? 1 / UIScreen.main.nativeScale : 0
    }

    private func dividerView() -> UIView {
        UIView().then {
            let frame = CGRect(x: 8, y: 0, width: view.frame.width - 16, height: 1 / UIScreen.main.nativeScale)
            let divider = UIView(frame: frame)
            $0.addSubview(divider)
            $0.backgroundColor = .clear
            divider.backgroundColor = .borderColor
        }
    }
}

extension ThreadDetailsViewController: NavigationChildController {
    func handleBackButtonTap() {
        let isRead = input.contains(where: { $0.rawMessage.isMessageRead })
        logger.logInfo("Back button. Are all messages read \(isRead)")
        onComplete(MessageAction.markAsRead(isRead), .init(thread: thread, folderPath: currentFolderPath, activeUserEmail: appContext.user.email))
        navigationController?.popViewController(animated: true)
    }
}
