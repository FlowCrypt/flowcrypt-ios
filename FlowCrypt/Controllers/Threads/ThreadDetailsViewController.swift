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
import UIKit

final class ThreadDetailsViewController: TableNodeViewController {
    private lazy var logger = Logger.nested(Self.self)
    private lazy var alertsFactory = AlertsFactory()

    class Input {
        var rawMessage: Message
        var isExpanded: Bool
        var shouldShowRecipientsList: Bool
        var processedMessage: ProcessedMessage?

        init(
            message: Message,
            isExpanded: Bool = false,
            shouldShowRecipientsList: Bool = false,
            processedMessage: ProcessedMessage? = nil
        ) {
            self.rawMessage = message
            self.isExpanded = isExpanded
            self.shouldShowRecipientsList = shouldShowRecipientsList
            self.processedMessage = processedMessage
        }
    }

    private enum Parts: Int, CaseIterable {
        case thread, message
    }

    private let appContext: AppContextWithUser
    private let draftGateway: DraftGateway?
    private let messageService: MessageService
    private let messageOperationsProvider: MessageOperationsProvider
    private let threadOperationsProvider: MessagesThreadOperationsProvider
    private var inboxItem: InboxItem
    private var input: [ThreadDetailsViewController.Input]

    let trashFolderProvider: TrashFolderProviderType
    var currentFolderPath: String {
        inboxItem.folderPath
    }
    private let onComposeMessageAction: ((ComposeMessageAction) -> Void)?
    private let onComplete: MessageActionCompletion

    init(
        appContext: AppContextWithUser,
        messageService: MessageService? = nil,
        inboxItem: InboxItem,
        onComposeMessageAction: ((ComposeMessageAction) -> Void)?,
        completion: @escaping MessageActionCompletion
    ) async throws {
        self.appContext = appContext
        let clientConfiguration = try await appContext.clientConfigurationService.configuration
        let localContactsProvider = LocalContactsProvider(
            encryptedStorage: appContext.encryptedStorage
        )
        let mailProvider = try appContext.getRequiredMailProvider()
        self.draftGateway = try mailProvider.draftGateway
        self.messageService = try messageService ?? MessageService(
            localContactsProvider: localContactsProvider,
            pubLookup: PubLookup(clientConfiguration: clientConfiguration, localContactsProvider: localContactsProvider),
            keyAndPassPhraseStorage: appContext.keyAndPassPhraseStorage,
            messageProvider: try mailProvider.messageProvider,
            combinedPassPhraseStorage: appContext.combinedPassPhraseStorage
        )
        self.threadOperationsProvider = try mailProvider.threadOperationsProvider
        self.messageOperationsProvider = try mailProvider.messageOperationsProvider
        self.trashFolderProvider = TrashFolderProvider(
            user: appContext.user,
            foldersService: FoldersService(
                encryptedStorage: appContext.encryptedStorage,
                remoteFoldersProvider: try mailProvider.remoteFoldersProvider
            )
        )
        self.inboxItem = inboxItem
        self.onComposeMessageAction = onComposeMessageAction
        self.onComplete = completion
        self.input = inboxItem.messages
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

        setupNavigationBar(inboxItem: inboxItem)
        expandThreadMessageAndMarkAsRead()
    }

    private func expandThreadMessageAndMarkAsRead() {
        Task {
            try await threadOperationsProvider.mark(
                messagesIds: inboxItem.messages.map(\.identifier),
                asRead: true,
                in: inboxItem.folderPath
            )
        }
        let indexOfSectionToExpand = input.firstIndex(where: { !$0.rawMessage.isRead })
            ?? input.lastIndex(where: { !$0.rawMessage.isDraft })
            ?? input.count - 1
        let indexPath = IndexPath(row: 0, section: indexOfSectionToExpand + 1)
        handleExpandTap(at: indexPath)
    }
}

extension ThreadDetailsViewController {

    private func handleExpandTap(at indexPath: IndexPath) {
        input[indexPath.section - 1].isExpanded.toggle()

        if input[indexPath.section - 1].isExpanded {
            UIView.animate(
                withDuration: 0.2,
                animations: {
                    if let threadNode = self.node.nodeForRow(at: indexPath) as? ThreadMessageInfoCellNode {
                        threadNode.expandNode.view.alpha = 0
                    }
                },
                completion: { [weak self] _ in
                    guard let self = self else { return }

                    if let processedMessage = self.input[indexPath.section - 1].processedMessage {
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

    private func handleRecipientsTap(at indexPath: IndexPath) {
        input[indexPath.section - 1].shouldShowRecipientsList.toggle()

        UIView.animate(withDuration: 0.3) {
            self.node.reloadSections([indexPath.section], with: .automatic)
        }
    }

    private func handleReplyTap(at indexPath: IndexPath) {
        composeNewMessage(at: indexPath, quoteType: .reply)
    }

    private func handleDraftTap(at indexPath: IndexPath) {
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

        let cancelAction = UIAlertAction(title: "cancel".localized, style: .cancel)
        cancelAction.accessibilityIdentifier = "aid-cancel-button"

        alert.addAction(createComposeNewMessageAlertAction(at: indexPath, type: .replyAll))
        alert.addAction(createComposeNewMessageAlertAction(at: indexPath, type: .forward))
        alert.addAction(cancelAction)

        present(alert, animated: true, completion: nil)
    }

    private func handleComposeMessageAction(_ action: ComposeMessageAction) {
        onComposeMessageAction?(action)

        switch action {
        case .update(let identifier):
            updateMessage(identifier: identifier)
        case .sent(let identifier):
            handleSentMessage(identifier: identifier)
        case .delete(let identifier):
            deleteMessage(identifier: identifier)
        }
    }

    private func updateMessage(identifier: MessageIdentifier) {
        Task {
            guard let messageId = identifier.messageId else { return }

            let processedMessage = try await getAndProcessMessage(
                identifier: messageId,
                folder: inboxItem.folderPath
            )

            let section: Int
            if let index = input.firstIndex(where: { $0.rawMessage.identifier == identifier.draftMessageId }) {
                section = index + 1
            } else {
                section = input.count + 1
            }

            handle(processedMessage: processedMessage, at: IndexPath(row: 0, section: section))
        }
    }

    private func handleSentMessage(identifier: MessageIdentifier) {
        Task {
            if let draftId = identifier.draftId,
                let index = input.firstIndex(where: { $0.rawMessage.identifier == draftId }) {
                input.remove(at: index)
                node.deleteSections([index + 1], with: .automatic)
            }

            guard let messageId = identifier.messageId else { return }

            let processedMessage = try await getAndProcessMessage(
                identifier: messageId,
                folder: inboxItem.folderPath
            )
            let indexPath = IndexPath(row: 0, section: input.count + 1)
            handle(processedMessage: processedMessage, at: indexPath)
        }
    }

    private func deleteMessage(identifier: MessageIdentifier) {
        guard let messageId = identifier.messageId,
              let index = input.firstIndex(where: {
                  $0.rawMessage.identifier == messageId
              })
        else { return }

        input.remove(at: index)
        node.deleteSections([index + 1], with: .automatic)
    }

    private func getAndProcessMessage(
        identifier: Identifier,
        folder: String,
        onlyLocalKeys: Bool = false
    ) async throws -> ProcessedMessage {
        return try await messageService.getAndProcess(
            identifier: identifier,
            folder: folder,
            onlyLocalKeys: onlyLocalKeys,
            userEmail: appContext.user.email,
            isUsingKeyManager: appContext.clientConfigurationService.configuration.isUsingKeyManager
        )
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

    private func handleAttachmentTap(at indexPath: IndexPath) {
        Task {
            do {
                let attachment = try await getAttachment(at: indexPath)
                hideSpinner()
                show(attachment: attachment)
            } catch {
                handleAttachmentDecryptError(error, at: indexPath)
            }
        }
    }

    private func getAttachment(at indexPath: IndexPath) async throws -> MessageAttachment {
        defer { node.reloadRows(at: [indexPath], with: .automatic) }

        let trace = Trace(id: "Attachment")
        let section = input[indexPath.section - 1]
        let attachmentIndex = indexPath.row - 2

        guard var attachment = section.processedMessage?.attachments[attachmentIndex] else {
            throw MessageServiceError.attachmentNotFound
        }

        if attachment.data == nil {
            showSpinner()
            attachment.data = try await messageService.download(
                attachment: attachment,
                messageId: section.rawMessage.identifier,
                progressHandler: { [weak self] progress in
                    self?.handleFetchProgress(state: .download(progress))
                }
            )
            section.processedMessage?.attachments[attachmentIndex] = attachment
        }

        if attachment.isEncrypted {
            handleFetchProgress(state: .decrypt)
            let decryptedAttachment = try await messageService.decrypt(
                attachment: attachment,
                userEmail: appContext.user.email
            )
            logger.logInfo("Got encrypted attachment - \(trace.finish())")

            input[indexPath.section - 1].processedMessage?.attachments[attachmentIndex] = decryptedAttachment
            return decryptedAttachment
        } else {
            logger.logInfo("Got not encrypted attachment - \(trace.finish())")
            input[indexPath.section - 1].processedMessage?.attachments[attachmentIndex] = attachment
            return attachment
        }
    }

    private func show(attachment: MessageAttachment) {
        let attachmentViewController = AttachmentViewController(file: attachment)
        navigationController?.pushViewController(attachmentViewController, animated: true)
    }

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

        Task {
            do {
                let composeVC = try await ComposeViewController(
                    appContext: appContext,
                    input: ComposeMessageInput(type: composeType),
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
}

extension ThreadDetailsViewController {
    private func fetchDecryptAndRenderMsg(at indexPath: IndexPath) {
        let message = input[indexPath.section - 1].rawMessage
        logger.logInfo("Start loading message")

        handleFetchProgress(state: .fetch)

        Task {
            do {
                var processedMessage = try await getAndProcessMessage(
                    identifier: message.identifier,
                    folder: inboxItem.folderPath,
                    onlyLocalKeys: true
                )

                if case .missingPubkey = processedMessage.signature {
                    processedMessage.signature = .pending
                    retryVerifyingSignatureWithRemotelyFetchedKeys(
                        message: message,
                        folder: inboxItem.folderPath,
                        indexPath: indexPath
                    )
                }
                handle(processedMessage: processedMessage, at: indexPath)
            } catch {
                handle(error: error, at: indexPath)
            }
        }
    }

    private func handle(processedMessage: ProcessedMessage, at indexPath: IndexPath) {
        hideSpinner()

        let messageIndex = indexPath.section - 1
        let isAlreadyProcessed = messageIndex < input.count && input[messageIndex].processedMessage != nil

        if !isAlreadyProcessed {
            if messageIndex < input.count {
                input[messageIndex].rawMessage = processedMessage.message
                input[messageIndex].processedMessage = processedMessage
                input[messageIndex].isExpanded = true
            } else {
                input.append(Input(message: processedMessage.message, isExpanded: true, processedMessage: processedMessage))
            }

            UIView.animate(
                withDuration: 0.2,
                animations: {
                    if indexPath.section < self.node.numberOfSections {
                        self.node.reloadSections([indexPath.section], with: .automatic)
                    } else {
                        self.node.insertSections([indexPath.section], with: .automatic)
                    }
                },
                completion: { [weak self] _ in
                    self?.node.scrollToRow(at: indexPath, at: .middle, animated: true)
                    self?.decryptDrafts()
                })
        } else {
            input[messageIndex].rawMessage = processedMessage.message
            input[messageIndex].processedMessage = processedMessage
            node.reloadSections([indexPath.section], with: .automatic)
        }
    }

    private func handle(error: Error, at indexPath: IndexPath) {
        logger.logInfo("Error \(error)")
        hideSpinner()

        switch error as? MessageServiceError {
        case .missingPassPhrase:
            handleWrongPassPhrase(indexPath: indexPath)
        default:
            // TODO: - Ticket - Improve error handling for ThreadDetailsViewController
            if let someError = error as NSError?, someError.code == Imap.Err.fetch.rawValue {
                // todo - the missing msg should be removed from the list in inbox view
                // reproduce: 1) load inbox 2) move msg to trash on another email client 3) open trashed message in inbox
                showToast("message_not_found_in_folder".localized + inboxItem.folderPath)
            } else {
                showRetryAlert(message: error.errorMessage, onRetry: { [weak self] _ in
                    self?.fetchDecryptAndRenderMsg(at: indexPath)
                }, onCancel: { [weak self] _ in
                    self?.navigationController?.popViewController(animated: true)
                })
            }
            navigationController?.popViewController(animated: true)
        }
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

    private func handleWrongPassPhrase(_ passPhrase: String? = nil, indexPath: IndexPath) {
        let title = passPhrase == nil
            ? "setup_enter_pass_phrase".localized
            : "setup_wrong_pass_phrase_retry".localized

        let alert = alertsFactory.makePassPhraseAlert(
            title: title,
            onCancel: { [weak self] in
                self?.navigationController?.popViewController(animated: true)
            },
            onCompletion: { [weak self] passPhrase in
                self?.handlePassPhraseEntry(passPhrase, indexPath: indexPath)
            }
        )

        present(alert, animated: true, completion: nil)
    }

    private func handlePassPhraseEntry(_ passPhrase: String, indexPath: IndexPath) {
        presentedViewController?.dismiss(animated: true)

        handleFetchProgress(state: .decrypt)

        Task {
            do {
                let matched = try await messageService.checkAndPotentiallySaveEnteredPassPhrase(
                    passPhrase,
                    userEmail: appContext.user.email
                )

                if matched {
                    let message = input[indexPath.section - 1].rawMessage

                    let processedMessage = try await messageService.decryptAndProcess(
                        message: message,
                        onlyLocalKeys: false,
                        userEmail: appContext.user.email,
                        isUsingKeyManager: appContext.clientConfigurationService.configuration.isUsingKeyManager
                    )

                    handle(processedMessage: processedMessage, at: indexPath)
                } else {
                    handleWrongPassPhrase(passPhrase, indexPath: indexPath)
                }
            } catch {
                handle(error: error, at: indexPath)
            }
        }
    }

    private func decryptDrafts() {
        Task {
            for (index, data) in input.enumerated() {
                guard data.rawMessage.isDraft && data.rawMessage.isPgp && data.processedMessage == nil else { continue }
                let indexPath = IndexPath(row: 0, section: index + 1)
                do {
                    let decryptedText = try await messageService.decrypt(
                        text: data.rawMessage.body.text,
                        userEmail: appContext.user.email,
                        isUsingKeyManager: appContext.clientConfigurationService.configuration.isUsingKeyManager
                    )

                    let processedMessage = ProcessedMessage(message: data.rawMessage, text: decryptedText, type: .plain, attachments: [])
                    handle(processedMessage: processedMessage, at: indexPath)
                } catch {
                    handle(error: error, at: indexPath)
                }
            }
        }
    }

    private func retryVerifyingSignatureWithRemotelyFetchedKeys(
        message: Message,
        folder: String,
        indexPath: IndexPath
    ) {
        Task {
            do {
                let processedMessage = try await getAndProcessMessage(
                    identifier: message.identifier,
                    folder: inboxItem.folderPath
                )
                handle(processedMessage: processedMessage, at: indexPath)
            } catch {
                let message = "message_signature_fail_reason".localizeWithArguments(error.errorMessage)
                input[indexPath.section - 1].processedMessage?.signature = .error(message)
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
    private func handle(action: MessageAction, error: Error? = nil) {
        hideSpinner()

        if let error = error {
            logger.logError("\(action.error ?? "Error: ") \(error)")
            return
        }

        onComplete(
            action,
            inboxItem
        )

        navigationController?.popViewController(animated: true)
    }

    func permanentlyDelete() {
        logger.logInfo("permanently delete")
        perform(action: .permanentlyDelete)
    }

    func moveToTrash(with trashPath: String) {
        logger.logInfo("move to trash \(trashPath)")
        perform(action: .moveToTrash)
    }

    func handleArchiveTap() {
        perform(action: .archive)
    }

    func handleMoveToInboxTap() {
        perform(action: .moveToInbox)
    }

    func handleMarkUnreadTap() {
        let messages = input.filter(\.isExpanded).map(\.rawMessage)

        guard messages.isNotEmpty else { return }

        perform(action: .markAsRead(false))
    }

    func perform(action: MessageAction) {
        Task {
            do {
                showSpinner()

                switch action {
                case .archive:
                    try await threadOperationsProvider.archive(
                        messagesIds: inboxItem.messages.map(\.identifier),
                        in: inboxItem.folderPath
                    )
                case .markAsRead(let isRead):
                    guard !isRead else { return }
                    Task { // Run mark as unread operation in another thread
                        try await threadOperationsProvider.markThreadAsUnread(
                            id: inboxItem.threadId,
                            folder: inboxItem.folderPath
                        )
                    }
                case .moveToTrash:
                    try await threadOperationsProvider.moveThreadToTrash(id: inboxItem.threadId, labels: inboxItem.labels)
                case .moveToInbox:
                    try await threadOperationsProvider.moveThreadToInbox(id: inboxItem.threadId)
                case .permanentlyDelete:
                    try await threadOperationsProvider.delete(id: inboxItem.threadId)
                }

                handle(action: action)
            } catch {
                handle(action: action, error: error)
            }
        }
    }
}

extension ThreadDetailsViewController: ASTableDelegate, ASTableDataSource {
    func numberOfSections(in tableNode: ASTableNode) -> Int {
        input.count + 1
    }

    func tableNode(_ tableNode: ASTableNode, numberOfRowsInSection section: Int) -> Int {
        guard section > 0, input[section - 1].isExpanded,
              !input[section - 1].rawMessage.isDraft
        else { return 1 }

        let attachmentsCount = input[section - 1].processedMessage?.attachments.count ?? 0
        return Parts.allCases.count + attachmentsCount
    }

    func tableNode(_ tableNode: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        return { [weak self] in
            guard let self = self else { return ASCellNode() }

            guard indexPath.section > 0 else {
                let subject = self.inboxItem.subject ?? "no subject"
                return MessageSubjectNode(subject.attributed(.medium(18)))
            }

            let messageIndex = indexPath.section - 1
            let message = self.input[messageIndex]

            if !message.rawMessage.isDraft && indexPath.row == 0 {
                return ThreadMessageInfoCellNode(
                    input: .init(threadMessage: message, index: messageIndex),
                    onReplyTap: { [weak self] _ in self?.handleReplyTap(at: indexPath) },
                    onMenuTap: { [weak self] _ in self?.handleMenuTap(at: indexPath) },
                    onRecipientsTap: { [weak self] _ in self?.handleRecipientsTap(at: indexPath) }
                )
            }

            if message.rawMessage.isDraft {
                return self.draftNode(messageIndex: messageIndex, isExpanded: message.isExpanded)
            }

            guard let processedMessage = message.processedMessage else {
                return ASCellNode()
            }

            guard indexPath.row > 1 else {
                return MessageTextSubjectNode(processedMessage.attributedMessage, index: messageIndex)
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
        default:
            let message = input[indexPath.section - 1]

            if message.rawMessage.isDraft {
                handleDraftTap(at: indexPath)
            }
        }
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        dividerView()
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        section > 0 && section < input.count ? 1 / UIScreen.main.nativeScale : 0
    }

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
        logger.logInfo("Back button. Messages are all read")
        onComplete(
            .markAsRead(true),
            inboxItem
        )
        navigationController?.popViewController(animated: true)
    }
}
