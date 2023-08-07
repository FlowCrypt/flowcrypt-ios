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
    private let alertsFactory: AlertsFactory
    lazy var logger = Logger.nested(Self.self)

    struct Input {
        var rawMessage: Message
        var isExpanded = false
        var shouldShowRecipientsList = false
        var processedMessage: ProcessedMessage?
    }

    let messageHelper: MessageHelper
    let messageActionsHelper: MessageActionsHelper

    private let filesManager: FilesManagerType
    lazy var attachmentManager = AttachmentManager(
        controller: self,
        filesManager: filesManager
    )

    let appContext: AppContextWithUser
    let messageOperationsApiClient: MessageOperationsApiClient
    let threadOperationsApiClient: MessagesThreadOperationsApiClient
    var inboxItem: InboxItem
    var input: [ThreadDetailsViewController.Input]

    var trashFolderPath: String? {
        get async throws {
            try await messageActionsHelper.trashFolderPath
        }
    }

    var currentFolderPath: String { inboxItem.folderPath }

    let onComposeMessageAction: ((ComposeMessageAction) -> Void)?
    let onComplete: MessageActionCompletion

    init(
        appContext: AppContextWithUser,
        messageHelper: MessageHelper? = nil,
        inboxItem: InboxItem,
        filesManager: FilesManagerType = FilesManager(),
        onComposeMessageAction: ((ComposeMessageAction) -> Void)?,
        onComplete: @escaping MessageActionCompletion
    ) async throws {
        self.appContext = appContext
        let clientConfiguration = try await appContext.clientConfigurationProvider.configuration
        let localContactsProvider = LocalContactsProvider(
            encryptedStorage: appContext.encryptedStorage
        )
        let mailProvider = try appContext.getRequiredMailProvider()
        self.messageHelper = try messageHelper ?? MessageHelper(
            localContactsProvider: localContactsProvider,
            pubLookup: PubLookup(
                clientConfiguration: clientConfiguration,
                localContactsProvider: localContactsProvider
            ),
            keyAndPassPhraseStorage: appContext.keyAndPassPhraseStorage,
            messageProvider: try mailProvider.messageProvider,
            combinedPassPhraseStorage: appContext.combinedPassPhraseStorage
        )
        self.alertsFactory = AlertsFactory(encryptedStorage: appContext.encryptedStorage)
        self.threadOperationsApiClient = try mailProvider.threadOperationsApiClient
        self.messageActionsHelper = try await MessageActionsHelper(
            appContext: appContext
        )
        self.messageOperationsApiClient = try mailProvider.messageOperationsApiClient
        self.filesManager = filesManager
        self.inboxItem = inboxItem
        self.onComposeMessageAction = onComposeMessageAction
        self.onComplete = onComplete
        self.input = inboxItem.messages
            .sorted(by: >)
            .map { Input(rawMessage: $0) }

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
            try await threadOperationsApiClient.mark(
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

    // MARK: - Message processing
    func fetchDecryptAndRenderMsg(at indexPath: IndexPath) {
        let rawMessage = input[indexPath.section - 1].rawMessage
        logger.logInfo("Start loading message")

        handleFetchProgress(state: .fetch)

        Task {
            do {
                let fetchedMessage = try await messageHelper.fetchMessage(
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
                    let data = try await messageHelper.download(
                        attachment: bodyAttachment,
                        messageId: processedMessage.message.identifier,
                        progressHandler: { [weak self] progress in
                            self?.handleFetchProgress(state: .download(progress))
                        }
                    )
                    handleFetchProgress(state: .decrypt)
                    let encryptedText = data.toStr()
                    processedMessage.text = try await messageHelper.decrypt(
                        text: encryptedText,
                        userEmail: appContext.user.email,
                        isUsingKeyManager: appContext.clientConfigurationProvider.configuration.isUsingKeyManager
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

    private func getAndProcessMessage(
        identifier: Identifier,
        onlyLocalKeys: Bool = false,
        forceFetch: Bool = true
    ) async throws -> ProcessedMessage {
        let message: Message

        if !forceFetch, let rawMessage = input.first(where: { $0.rawMessage.identifier == identifier })?.rawMessage {
            message = rawMessage
        } else {
            message = try await messageHelper.fetchMessage(
                identifier: identifier,
                folder: inboxItem.folderPath
            )
        }

        return try await messageHelper.process(
            message: message,
            onlyLocalKeys: onlyLocalKeys,
            userEmail: appContext.user.email,
            isUsingKeyManager: appContext.clientConfigurationProvider.configuration.isUsingKeyManager
        )
    }

    func handle(processedMessage: ProcessedMessage, at indexPath: IndexPath) {
        hideSpinner()

        let messageIndex = indexPath.section - 1
        let isAlreadyProcessed = messageIndex < input.count && input[messageIndex].processedMessage != nil
        let messageInput = Input(
            rawMessage: processedMessage.message,
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

    private func decryptDrafts() {
        for index in input.indices where input[index].rawMessage.isDraft {
            processDraft(at: index)
        }
    }

    private func processDraft(at index: Int) {
        let indexPath = IndexPath(row: 0, section: index + 1)

        Task {
            do {
                if input[index].rawMessage.body.text.isEmpty {
                    try await fetchDraft(at: index)
                }

                let data = input[index]

                guard data.rawMessage.isPgp, data.processedMessage == nil else { return }

                let decryptedText = try await messageHelper.decrypt(
                    text: data.rawMessage.body.text,
                    userEmail: appContext.user.email,
                    isUsingKeyManager: appContext.clientConfigurationProvider.configuration.isUsingKeyManager
                )

                let processedMessage = ProcessedMessage(
                    message: data.rawMessage,
                    text: decryptedText,
                    type: .plain
                )
                handle(processedMessage: processedMessage, at: indexPath)
            } catch {
                handle(error: error, at: indexPath)
            }
        }
    }

    private func fetchDraft(at index: Int) async throws {
        let id = input[index].rawMessage.identifier
        let message = try await messageHelper.fetchMessage(
            identifier: id,
            folder: inboxItem.folderPath
        )
        input[index].rawMessage = message
    }

    // MARK: - Compose message actions
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

    // MARK: - Error handling
    private func handle(error: Error, at indexPath: IndexPath) {
        logger.logInfo("Error \(error)")
        hideSpinner()

        switch error as? MessageHelperError {
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

    private func handleWrongPassPhrase(_ passPhrase: String? = nil, indexPath: IndexPath) {
        let title = passPhrase == nil
            ? "setup_enter_pass_phrase".localized
            : "setup_wrong_pass_phrase_retry".localized

        alertsFactory.makePassPhraseAlert(
            viewController: self,
            title: title,
            onCancel: { [weak self] in
                self?.navigationController?.popViewController(animated: true)
            },
            onCompletion: { [weak self] passPhrase in
                self?.handlePassPhraseEntry(passPhrase, indexPath: indexPath)
            }
        )
    }

    private func handlePassPhraseEntry(_ passPhrase: String, indexPath: IndexPath) {
        presentedViewController?.dismiss(animated: true)

        handleFetchProgress(state: .decrypt)

        Task {
            do {
                let matched = try await messageHelper.checkAndPotentiallySaveEnteredPassPhrase(
                    passPhrase,
                    userEmail: appContext.user.email
                )

                if matched {
                    let message = input[indexPath.section - 1].rawMessage

                    let processedMessage = try await messageHelper.decryptAndProcess(
                        message: message,
                        onlyLocalKeys: false,
                        userEmail: appContext.user.email,
                        isUsingKeyManager: appContext.clientConfigurationProvider.configuration.isUsingKeyManager
                    )

                    alertsFactory.passphraseCheckSucceed()
                    handle(processedMessage: processedMessage, at: indexPath)
                } else {
                    hideSpinner()
                    alertsFactory.passphraseCheckFailed()
                    handleWrongPassPhrase(passPhrase, indexPath: indexPath)
                }
            } catch {
                handle(error: error, at: indexPath)
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

    func handleFetchProgress(state: MessageFetchState) {
        switch state {
        case .fetch:
            showSpinner(isUserInteractionEnabled: true)
        case let .download(progress):
            showSpinnerWithProgress("downloading_title".localized, progress: progress)
        case .decrypt:
            showSpinner("processing_title".localized)
        }
    }
}

// MARK: - NavigationChildController
extension ThreadDetailsViewController: NavigationChildController {
    func handleBackButtonTap() {
        logger.logInfo("Back button. Messages are all read")
        onComplete(
            .markAsRead,
            inboxItem
        )
        navigationController?.popViewController(animated: true)
    }
}
