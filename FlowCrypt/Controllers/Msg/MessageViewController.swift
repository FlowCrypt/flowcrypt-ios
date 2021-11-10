//
// © 2017-2019 FlowCrypt Limited. All rights reserved.
//

import AsyncDisplayKit
import FlowCryptCommon
import FlowCryptUI

/**
 * View controller to render an email message (sender, subject, message body, attachments)
 * Also contains buttons to archive, move to trash, move to inbox, mark as unread, and reply
 */
final class MessageViewController: TableNodeViewController {
    struct Input {
        var objMessage: Message
        var bodyMessage: Data?
        var path = ""
    }

    enum Sections: Int, CaseIterable {
        case main, attributes
    }

    enum Parts: Int, CaseIterable {
        case sender, subject, text

        var indexPath: IndexPath {
            IndexPath(row: rawValue, section: 0)
        }
    }

    private let onCompletion: MessageActionCompletion

    private var input: MessageViewController.Input
    private let decorator: MessageViewDecorator
    private let messageOperationsProvider: MessageOperationsProvider
    private let filesManager: FilesManagerType
    private let serviceActor: ServiceActor
    private var processedMessage: ProcessedMessage = .empty

    let trashFolderProvider: TrashFolderProviderType
    var currentFolderPath: String {
        input.path
    }

    private lazy var attachmentManager = AttachmentManager(
        controller: self,
        filesManager: filesManager
    )

    init(
        messageService: MessageService = MessageService(),
        messageOperationsProvider: MessageOperationsProvider = MailProvider.shared.messageOperationsProvider,
        messageProvider: MessageProvider = MailProvider.shared.messageProvider,
        contactsService: ContactsServiceType = ContactsService(),
        decorator: MessageViewDecorator = MessageViewDecorator(dateFormatter: DateFormatter()),
        trashFolderProvider: TrashFolderProviderType = TrashFolderProvider(),
        filesManager: FilesManagerType = FilesManager(),
        input: MessageViewController.Input,
        completion: @escaping MessageActionCompletion
    ) {
        self.messageOperationsProvider = messageOperationsProvider
        self.input = input
        self.decorator = decorator
        self.trashFolderProvider = trashFolderProvider
        self.onCompletion = completion
        self.filesManager = filesManager
        self.serviceActor = ServiceActor(
            messageService: messageService,
            messageProvider: messageProvider,
            contactsService: contactsService
        )

        super.init(node: TableNode())
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigationBar()
        fetchDecryptAndRenderMsg()
    }

    private func setupUI() {
        node.do {
            $0.delegate = self
            $0.dataSource = self
            $0.view.keyboardDismissMode = .interactive
        }
    }
}

// MARK: - Message
extension MessageViewController {
    private func fetchDecryptAndRenderMsg() {
        handleFetchProgress(state: .fetch)

        Task {
            do {
                processedMessage = try await serviceActor.fetchDecryptAndRenderMsg(
                    message: input.objMessage,
                    path: input.path,
                    progressHandler: { [weak self] in self?.handleFetchProgress(state: $0)})
                handleReceivedMessage()
            } catch {
                handleError(error)
            }
        }
    }

    private func handlePassPhraseEntry(rawMimeData: Data, with passPhrase: String) {
        Task {
            do {
                let matched = try await serviceActor.checkAndPotentiallySaveEnteredPassPhrase(passPhrase)
                if matched {
                    handleFetchProgress(state: .decrypt)
                    processedMessage = try await serviceActor.decryptAndProcessMessage(mime: rawMimeData, sender: input.objMessage.sender)
                    handleReceivedMessage()
                } else {
                    handleWrongPassPhrase(for: rawMimeData, with: passPhrase)
                }
            } catch {
                handleError(error)
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

    private func handleReceivedMessage() {
        hideSpinner()
        node.reloadData()
        asyncMarkAsReadIfNotAlreadyMarked()
    }

    private func asyncMarkAsReadIfNotAlreadyMarked() {
        Task {
            do {
                try await messageOperationsProvider.markAsRead(message: input.objMessage, folder: input.path)
                input.objMessage = self.input.objMessage.markAsRead(true)
            } catch {
                showToast("Could not mark message as read: \(error)")
            }
        }
    }

    private func handleOpSuccess(operation: MessageAction) {
        hideSpinner()
        operation.text.flatMap { showToast($0) }

        navigationController?.popViewController(animated: true) { [weak self] in
            guard let self = self else { return }
            self.onCompletion(operation, .init(message: self.input.objMessage))
        }
    }
}

// MARK: - Error Handling

extension MessageViewController {
    private func handleError(_ error: Error) {
        hideSpinner()

        switch error as? MessageServiceError {
        case let .missingPassPhrase(rawMimeData):
            handleMissingPassPhrase(for: rawMimeData)
        case let .wrongPassPhrase(rawMimeData, passPhrase):
            handleWrongPassPhrase(for: rawMimeData, with: passPhrase)
        case let .keyMismatch(rawMimeData):
            handleKeyMismatch(for: rawMimeData)

        default:
            // TODO: - Ticket - Improve error handling for MessageViewController
            if let someError = error as NSError?, someError.code == Imap.Err.fetch.rawValue {
                // todo - the missing msg should be removed from the list in inbox view
                // reproduce: 1) load inbox 2) move msg to trash on another email client 3) open trashed message in inbox
                showToast("Message not found in folder: \(input.path)")
            } else {
                // todo - this should be a retry / cancel alert
                showAlert(error: error, message: "message_failed_open".localized + "\n\n\(error)")
            }
            navigationController?.popViewController(animated: true)
        }
    }

    private func handleMissingPassPhrase(for rawMimeData: Data) {
        let alert = AlertsFactory.makePassPhraseAlert(
            onCancel: { [weak self] in
                self?.navigationController?.popViewController(animated: true)
            },
            onCompletion: { [weak self] passPhrase in
                self?.handlePassPhraseEntry(rawMimeData: rawMimeData, with: passPhrase)
            })

        present(alert, animated: true, completion: nil)
    }

    private func handleWrongPassPhrase(for rawMimeData: Data, with phrase: String) {
        let alert = AlertsFactory.makeWrongPassPhraseAlert(
            onCancel: { [weak self] in
                self?.navigationController?.popViewController(animated: true)
            },
            onCompletion: { [weak self] passPhrase in
                self?.handlePassPhraseEntry(rawMimeData: rawMimeData, with: passPhrase)
            })
        present(alert, animated: true, completion: nil)
    }

    private func handleKeyMismatch(for rawMimeData: Data) {
        let alert = UIAlertController(
            title: "error_key_mismatch".localized,
            message: nil, preferredStyle: .alert
        )
        alert.addAction(
            UIAlertAction(
                title: "go_back".localized,
                style: .cancel,
                handler: { [weak self] _ in
                    self?.navigationController?.popViewController(animated: true)
                }
            )
        )
        alert.addAction(
            UIAlertAction(
                title: "message_open_anyway".localized,
                style: .default,
                handler: { [weak self] _ in
                    guard let self = self else { return }
                    self.processedMessage = ProcessedMessage(rawMimeData: rawMimeData,
                                                             text: String(data: rawMimeData, encoding: .utf8) ?? "",
                                                             attachments: [],
                                                             messageType: .encrypted,
                                                             signature: .unknown)
                    self.handleReceivedMessage()
                }
            )
        )
        present(alert, animated: true, completion: nil)
    }

    private func handleOpErr(operation: MessageAction) {
        hideSpinner()
        operation.error.flatMap { showToast($0) }
    }
}

// MARK: - Handle Actions

extension MessageViewController: MessageActionsHandler {

    func handleMarkUnreadTap() {
        Task {
            do {
                try await messageOperationsProvider.markAsUnread(message: input.objMessage, folder: input.path)
                onCompletion(MessageAction.markAsRead(false), .init(message: self.input.objMessage))
                navigationController?.popViewController(animated: true)
            } catch {
                showToast("Could not mark message as unread: \(error)")
            }
        }
    }

    func handleArchiveTap() {
        Task {
            do {
                showSpinner()
                try await messageOperationsProvider.archiveMessage(message: input.objMessage, folderPath: input.path)
                handleOpSuccess(operation: .archive)
            } catch {
                handleOpErr(operation: .archive)
            }
        }
    }

    func permanentlyDelete() {
        Task {
            do {
                try await messageOperationsProvider.delete(message: self.input.objMessage, form: self.input.path)
                handleOpSuccess(operation: .permanentlyDelete)
            } catch {
                handleOpErr(operation: .archive)
            }
        }
    }

    func moveToTrash(with trashPath: String) {
        Task {
            do {
                try await messageOperationsProvider.moveMessageToTrash(
                    message: input.objMessage,
                    trashPath: trashPath,
                    from: input.path
                )
                handleOpSuccess(operation: .moveToTrash)
            } catch {
                handleOpErr(operation: .moveToTrash)
            }
        }
    }

    private func handleReplyTap() {
        guard let email = DataService.shared.email else { return }

        let replyInfo = ComposeMessageInput.ReplyInfo(
            recipient: input.objMessage.sender,
            subject: input.objMessage.subject,
            mime: processedMessage.rawMimeData,
            sentDate: input.objMessage.date,
            message: processedMessage.text,
            threadId: input.objMessage.threadId
        )

        let composeInput = ComposeMessageInput(type: .reply(replyInfo))
        navigationController?.pushViewController(
            ComposeViewController(email: email, input: composeInput),
            animated: true
        )
    }
}

// MARK: - NavigationChildController

extension MessageViewController: NavigationChildController {
    func handleBackButtonTap() {
        onCompletion(MessageAction.markAsRead(true), .init(message: input.objMessage))
        navigationController?.popViewController(animated: true)
    }
}

// MARK: - ASTableDelegate, ASTableDataSource

extension MessageViewController: ASTableDelegate, ASTableDataSource {
    func numberOfSections(in tableNode: ASTableNode) -> Int {
        Sections.allCases.count
    }

    func tableNode(_: ASTableNode, numberOfRowsInSection section: Int) -> Int {
        guard let section = Sections(rawValue: section) else {
            return 0
        }
        switch section {
        case .main:
            return Parts.allCases.count
        case .attributes:
            return processedMessage.attachments.count
        }
    }

    func tableNode(_ tableNode: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        return { [weak self] in
            guard let self = self, let section = Sections(rawValue: indexPath.section) else { return ASCellNode() }

            switch section {
            case .main:
                return self.mainSectionNode(for: indexPath.row)
            case .attributes:
                return self.attachmentNode(for: indexPath.row)
            }
        }
    }

    private func mainSectionNode(for index: Int) -> ASCellNode {
        guard let part = Parts(rawValue: index) else { return ASCellNode() }

        let senderTitle = decorator.attributed(
            title: input.objMessage.sender ?? "(unknown sender)"
        )
        let subject = decorator.attributed(
            subject: input.objMessage.subject ?? "(no subject)"
        )
        let time = decorator.attributed(
            date: input.objMessage.date
        )

        switch part {
        case .sender:
            return MessageSenderNode(senderTitle) { [weak self] in
                self?.handleReplyTap()
            }
        case .subject:
            return MessageSubjectAndTimeNode(subject, time: time)
        case .text:
            return MessageTextSubjectNode(self.processedMessage.attributedMessage)
        }
    }

    private func attachmentNode(for index: Int) -> ASCellNode {
        let attachment = processedMessage.attachments[index]
        return AttachmentNode(
            input: .init(
                msgAttachment: attachment
            ),
            onDownloadTap: { [weak self] in self?.attachmentManager.open(attachment) }
        )
    }
}

// TODO temporary solution for background execution problem
private actor ServiceActor {
    private let messageService: MessageService
    private let messageProvider: MessageProvider
    private let contactsService: ContactsServiceType

    init(messageService: MessageService,
         messageProvider: MessageProvider,
         contactsService: ContactsServiceType) {
        self.messageService = messageService
        self.messageProvider = messageProvider
        self.contactsService = contactsService
    }

    func fetchDecryptAndRenderMsg(message: Message, path: String,
                                  progressHandler: ((MessageFetchState) -> Void)?) async throws -> ProcessedMessage {
        let rawMimeData = try await messageProvider.fetchMsg(message: message,
                                                             folder: path,
                                                             progressHandler: progressHandler)

        progressHandler?(.decrypt)

        return try await decryptAndProcessMessage(mime: rawMimeData, sender: message.sender)
    }

    func checkAndPotentiallySaveEnteredPassPhrase(_ passPhrase: String) async throws -> Bool {
        try await messageService.checkAndPotentiallySaveEnteredPassPhrase(passPhrase)
    }

    func decryptAndProcessMessage(mime: Data, sender: String?) async throws -> ProcessedMessage {
        let pubKeys: [String]
        if let sender = sender {
            pubKeys = contactsService.retrievePubKeys(for: sender)
        } else {
            pubKeys = []
        }

        return try await messageService.decryptAndProcessMessage(mime: mime, verificationPubKeys: pubKeys)
    }
}
