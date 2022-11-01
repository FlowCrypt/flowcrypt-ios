//
//  ThreadDetailsViewController.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 12.10.2021
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import AsyncDisplayKit
import FlowCryptCommon
import FlowCryptUI
import UIKit

final class ThreadDetailsViewController: TableNodeViewController {
    lazy var logger = Logger.nested(Self.self)
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

    let appContext: AppContextWithUser
    private let draftGateway: DraftGateway?
    private let messageService: MessageService
    let messageOperationsProvider: MessageOperationsProvider
    let threadOperationsProvider: MessagesThreadOperationsProvider
    var inboxItem: InboxItem
    var input: [ThreadDetailsViewController.Input]

    let trashFolderProvider: TrashFolderProviderType
    var currentFolderPath: String {
        inboxItem.folderPath
    }

    let onComposeMessageAction: ((ComposeMessageAction) -> Void)?
    let onComplete: MessageActionCompletion

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
    func handleComposeMessageAction(_ action: ComposeMessageAction) {
        onComposeMessageAction?(action)

        switch action {
        case let .update(identifier):
            updateMessage(identifier: identifier)
        case let .sent(identifier):
            handleSentMessage(identifier: identifier)
        case let .delete(identifier):
            deleteMessage(identifier: identifier)
        }
    }

    private func updateMessage(identifier: MessageIdentifier) {
        Task {
            guard let messageId = identifier.messageId else { return }

            let processedMessage = try await getAndProcessMessage(identifier: messageId)

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

            let processedMessage = try await getAndProcessMessage(identifier: messageId)
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
        onlyLocalKeys: Bool = false,
        forceFetch: Bool = true
    ) async throws -> ProcessedMessage {
        let message: Message

        if !forceFetch, let rawMessage = input.first(where: { $0.rawMessage.identifier == identifier })?.rawMessage {
            message = rawMessage
        } else {
            message = try await messageService.fetchMessage(identifier: identifier, folder: inboxItem.folderPath)
        }

        return try await messageService.process(
            message: message,
            onlyLocalKeys: onlyLocalKeys,
            userEmail: appContext.user.email,
            isUsingKeyManager: appContext.clientConfigurationService.configuration.isUsingKeyManager
        )
    }

    func handleAttachmentTap(at indexPath: IndexPath) {
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
        let sectionIndex = indexPath.section - 1
        let section = input[sectionIndex]
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

            input[sectionIndex].processedMessage?.attachments[attachmentIndex] = decryptedAttachment
            return decryptedAttachment
        } else {
            logger.logInfo("Got not encrypted attachment - \(trace.finish())")
            input[sectionIndex].processedMessage?.attachments[attachmentIndex] = attachment
            return attachment
        }
    }

    private func show(attachment: MessageAttachment) {
        navigationController?.pushViewController(
            AttachmentViewController(file: attachment),
            animated: true
        )
    }
}

extension ThreadDetailsViewController {
    func fetchDecryptAndRenderMsg(at indexPath: IndexPath) {
        let rawMessage = input[indexPath.section - 1].rawMessage
        logger.logInfo("Start loading message")

        handleFetchProgress(state: .fetch)

        Task {
            do {
                let fetchedMessage = try await messageService.fetchMessage(
                    identifier: rawMessage.identifier,
                    folder: inboxItem.folderPath
                )

                input[indexPath.section - 1].rawMessage = fetchedMessage

                var processedMessage = try await getAndProcessMessage(
                    identifier: rawMessage.identifier,
                    onlyLocalKeys: true,
                    forceFetch: false
                )

                if processedMessage.text.isEmpty,
                   let bodyAttachment = processedMessage.message.body.attachment {
                    let data = try await messageService.download(
                        attachment: bodyAttachment,
                        messageId: processedMessage.message.identifier,
                        progressHandler: { [weak self] progress in
                            self?.handleFetchProgress(state: .download(progress))
                        }
                    )
                    handleFetchProgress(state: .decrypt)
                    let encryptedText = data.toStr()
                    processedMessage.text = try await messageService.decrypt(
                        text: encryptedText,
                        userEmail: appContext.user.email,
                        isUsingKeyManager: appContext.clientConfigurationService.configuration.isUsingKeyManager
                    )
                }

                if case .missingPubkey = processedMessage.signature {
                    processedMessage.signature = .pending
                    retryVerifyingSignatureWithRemotelyFetchedKeys(
                        message: rawMessage,
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

    func handle(processedMessage: ProcessedMessage, at indexPath: IndexPath) {
        hideSpinner()

        let messageIndex = indexPath.section - 1
        let isAlreadyProcessed = messageIndex < input.count && input[messageIndex].processedMessage != nil
        let messageInput = Input(
            message: processedMessage.message,
            isExpanded: true,
            processedMessage: processedMessage
        )

        if !isAlreadyProcessed {
            if messageIndex < input.count {
                input[messageIndex].rawMessage = messageInput.rawMessage
                input[messageIndex].processedMessage = messageInput.processedMessage
                input[messageIndex].isExpanded = messageInput.isExpanded
            } else {
                input.append(messageInput)
            }

            UIView.animate(
                withDuration: 0.2,
                animations: {
                    if indexPath.section < self.node.numberOfSections {
                        self.node.reloadSections([indexPath.section], with: .automatic)
                    } else {
                        self.node.insertSections([indexPath.section], with: .automatic)
                        if indexPath.section > 0 {
                            self.node.reloadSections([indexPath.section - 1], with: .automatic)
                        }
                    }
                },
                completion: { [weak self] _ in
                    self?.node.scrollToRow(at: indexPath, at: .middle, animated: true)
                    self?.decryptDrafts()
                }
            )
        } else {
            input[messageIndex].rawMessage = messageInput.rawMessage
            input[messageIndex].processedMessage = messageInput.processedMessage
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
                showRetryAlert(
                    message: error.errorMessage,
                    onRetry: { [weak self] _ in self?.fetchDecryptAndRenderMsg(at: indexPath) },
                    onCancel: { [weak self] _ in self?.navigationController?.popViewController(animated: true) }
                )
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
                guard data.rawMessage.isDraft, data.rawMessage.isPgp, data.processedMessage == nil else { continue }
                let indexPath = IndexPath(row: 0, section: index + 1)
                do {
                    let decryptedText = try await messageService.decrypt(
                        text: data.rawMessage.body.text,
                        userEmail: appContext.user.email,
                        isUsingKeyManager: appContext.clientConfigurationService.configuration.isUsingKeyManager
                    )

                    let processedMessage = ProcessedMessage(
                        message: data.rawMessage,
                        text: decryptedText,
                        type: .plain,
                        attachments: []
                    )
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
                    forceFetch: false
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
        case let .download(progress):
            updateSpinner(label: "downloading_title".localized, progress: progress)
        case .decrypt:
            updateSpinner(label: "processing_title".localized)
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
