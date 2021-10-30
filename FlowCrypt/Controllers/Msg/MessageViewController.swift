//
// © 2017-2019 FlowCrypt Limited. All rights reserved.
//

import AsyncDisplayKit
import FlowCryptCommon
import FlowCryptUI
import Promises
import Combine

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

    enum MessageAction {
        case moveToTrash, archive, changeReadFlag, permanentlyDelete

        var text: String? {
            switch self {
            case .moveToTrash: return "email_removed".localized
            case .archive: return "email_archived".localized
            case .permanentlyDelete: return "email_deleted".localized
            case .changeReadFlag: return nil
            }
        }

        var error: String? {
            switch self {
            case .moveToTrash: return "error_move_trash".localized
            case .archive: return "error_archive".localized
            case .permanentlyDelete: return "error_permanently_delete".localized
            case .changeReadFlag: return nil
            }
        }
    }

    typealias MsgViewControllerCompletion = (MessageAction, Message) -> Void
    private let onCompletion: MsgViewControllerCompletion?

    private var cancellable = Set<AnyCancellable>()

    private var input: MessageViewController.Input
    private let decorator: MessageViewDecorator
    private let messageService: MessageService
    private let messageProvider: MessageProvider
    private let messageOperationsProvider: MessageOperationsProvider
    private let trashFolderProvider: TrashFolderProviderType
    private let filesManager: FilesManagerType
    private var processedMessage: ProcessedMessage = .empty

    init(
        messageService: MessageService = MessageService(),
        messageOperationsProvider: MessageOperationsProvider = MailProvider.shared.messageOperationsProvider,
        messageProvider: MessageProvider = MailProvider.shared.messageProvider,
        decorator: MessageViewDecorator = MessageViewDecorator(dateFormatter: DateFormatter()),
        trashFolderProvider: TrashFolderProviderType = TrashFolderProvider(),
        filesManager: FilesManagerType = FilesManager(),
        input: MessageViewController.Input,
        completion: MsgViewControllerCompletion?
    ) {
        self.messageService = messageService
        self.messageOperationsProvider = messageOperationsProvider
        self.input = input
        self.decorator = decorator
        self.trashFolderProvider = trashFolderProvider
        self.onCompletion = completion
        self.filesManager = filesManager
        self.messageProvider = messageProvider

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

    private func setupNavigationBar() {
        trashFolderProvider.getTrashFolderPath()
            .then(on: .main) { [weak self] path in
                self?.setupNavigationBarItems(with: path)
            }
    }

    private func setupNavigationBarItems(with trashFolderPath: String?) {
        let helpButton = NavigationBarItemsView.Input(image: UIImage(named: "help_icn"), action: (self, #selector(handleInfoTap)))
        let archiveButton = NavigationBarItemsView.Input(image: UIImage(named: "archive"), action: (self, #selector(handleArchiveTap)))
        let trashButton = NavigationBarItemsView.Input(image: UIImage(named: "trash"), action: (self, #selector(handleTrashTap)))
        let unreadButton = NavigationBarItemsView.Input(image: UIImage(named: "mail"), action: (self, #selector(handleMarkUnreadTap)))

        let items: [NavigationBarItemsView.Input]
        switch input.path.lowercased() {
        case trashFolderPath?.lowercased():
            // in case we are in trash folder ([Gmail]/Trash or Deleted for Outlook, etc)
            // we need to have only help and trash buttons
            items = [helpButton, trashButton]

        // TODO: - Ticket - Check if this should be fixed
        case "inbox":
            // for Gmail inbox we also need to have archive and unread buttons
            items = [helpButton, archiveButton, trashButton, unreadButton]
        default:
            // in any other folders
            items = [helpButton, trashButton, unreadButton]
        }

        navigationItem.rightBarButtonItem = NavigationBarItemsView(with: items)
    }
}

// MARK: - Message

extension MessageViewController {
    private func fetchDecryptAndRenderMsg() {
        showSpinner("loading_title".localized, isUserInteractionEnabled: true)

        Promise { [weak self] in
            guard let self = self else { return }
            let rawMimeData = try awaitPromise(self.messageProvider.fetchMsg(message: self.input.objMessage, folder: self.input.path))
            self.processedMessage = try awaitPromise(self.messageService.decryptAndProcessMessage(mime: rawMimeData))
        }
        .then(on: .main) { [weak self] in
            self?.handleReceivedMessage()
        }
        .catch(on: .main) { [weak self] error in
            self?.handleError(error)
        }
    }

    private func handlePassPhraseEntry(rawMimeData: Data, with passPhrase: String) {
        showSpinner("loading_title".localized, isUserInteractionEnabled: true)
        do { // todo - should be a task on non-main thread?
            let matched = try messageService.checkAndPotentiallySaveEnteredPassPhrase(passPhrase)
            if matched {
                self.processedMessage = try awaitPromise(self.messageService.decryptAndProcessMessage(mime: rawMimeData))
                self.handleReceivedMessage()
            } else {
                handleWrongPathPhrase(for: rawMimeData, with: passPhrase)
            }
        } catch {
            self.handleError(error)
        }
    }

    private func handleReceivedMessage() {
        hideSpinner()
        node.reloadData()
        asyncMarkAsReadIfNotAlreadyMarked()
    }

    private func asyncMarkAsReadIfNotAlreadyMarked() {
        messageOperationsProvider.markAsRead(message: input.objMessage, folder: input.path)
            .then(on: .main) { [weak self] in
                guard let self = self else { return }
                self.input.objMessage = self.input.objMessage.markAsRead(true)
            }
            .catch(on: .main) { [weak self] error in
                self?.showToast("Could not mark message as read: \(error)")
            }
    }

    private func handleOpSuccess(operation: MessageAction) {
        hideSpinner()
        operation.text.flatMap { showToast($0) }

        navigationController?.popViewController(animated: true) { [weak self] in
            guard let self = self else { return }
            self.onCompletion?(operation, self.input.objMessage)
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
            handleWrongPathPhrase(for: rawMimeData, with: passPhrase)
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

    private func handleWrongPathPhrase(for rawMimeData: Data, with phrase: String) {
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
                                                              messageType: .encrypted)
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

extension MessageViewController {
    @objc private func handleInfoTap() {
        showToast("Email us at human@flowcrypt.com")
    }

    @objc private func handleMarkUnreadTap() {
        messageOperationsProvider.markAsUnread(message: input.objMessage, folder: input.path)
            .then(on: .main) { [weak self] in
                guard let self = self else { return }
                self.input.objMessage = self.input.objMessage.markAsRead(false)
                self.onCompletion?(MessageAction.changeReadFlag, self.input.objMessage)
                self.navigationController?.popViewController(animated: true)
            }
            .catch(on: .main) { [weak self] error in
                self?.showToast("Could not mark message as unread: \(error)")
            }
    }

    @objc private func handleAttachmentTap() {
        showToast("Downloading attachments is not implemented yet")
    }

    @objc private func handleTrashTap() {
        showSpinner()

        trashFolderProvider.getTrashFolderPath()
            .then { [weak self] trashPath in
                guard let strongSelf = self, let path = trashPath else {
                    self?.permanentlyDelete()
                    return
                }

                strongSelf.input.path == trashPath
                    ? strongSelf.permanentlyDelete()
                    : strongSelf.moveToTrash(with: path)
            }
            .catch(on: .main) { error in
                self.showToast(error.localizedDescription)
            }
    }

    private func permanentlyDelete() {
        Promise<Bool> { [weak self] () -> Bool in
            guard let self = self else { throw AppErr.nilSelf }
            guard try awaitPromise(self.awaitUserConfirmation(title: "You're about to permanently delete a message")) else { return false }
            try awaitPromise(self.messageOperationsProvider.delete(message: self.input.objMessage, form: self.input.path))
            return true
        }
        .then(on: .main) { [weak self] didPerformOp in
            guard didPerformOp else { self?.hideSpinner(); return }
            self?.handleOpSuccess(operation: .permanentlyDelete)
        }.catch(on: .main) { [weak self] _ in
            self?.handleOpErr(operation: .permanentlyDelete)
        }
    }

    private func awaitUserConfirmation(title: String) -> Promise<Bool> {
        Promise<Bool>(on: .main) { [weak self] resolve, _ in
            guard let self = self else { throw AppErr.nilSelf }
            let alert = UIAlertController(title: "Are you sure?", message: title, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { _ in resolve(false) }))
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in resolve(true) }))
            self.present(alert, animated: true, completion: nil)
        }
    }

    private func moveToTrash(with trashPath: String) {
        messageOperationsProvider.moveMessageToTrash(
            message: input.objMessage,
            trashPath: trashPath,
            from: input.path
        )
        .then(on: .main) { [weak self] in
            self?.handleOpSuccess(operation: .moveToTrash)
        }
        .catch(on: .main) { [weak self] _ in
            self?.handleOpErr(operation: .moveToTrash)
        }
    }

    @objc private func handleArchiveTap() {
        showSpinner()
        messageOperationsProvider.archiveMessage(message: input.objMessage, folderPath: input.path)
            .then(on: .main) { [weak self] _ in
                self?.handleOpSuccess(operation: .archive)
            }
            .catch(on: .main) { [weak self] _ in // todo - specific error should be toasted or shown
                self?.handleOpErr(operation: .archive)
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
        onCompletion?(MessageAction.changeReadFlag, input.objMessage)
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
            return MessageSubjectNode(subject, time: time)
        case .text:
            let messageInput = self.decorator.attributedMessage(from: self.processedMessage)
            return MessageTextSubjectNode(messageInput)
        }
    }

    private func attachmentNode(for index: Int) -> ASCellNode {
        AttachmentNode(
            input: .init(
                msgAttachment: processedMessage.attachments[index]
            ),
            onDownloadTap: { [weak self] in
                guard let self = self else { return }
                self.filesManager.saveToFilesApp(file: self.processedMessage.attachments[index], from: self)
                    .sinkFuture(
                        receiveValue: {},
                        receiveError: { error in
                            self.showToast(
                                "\("message_attachment_saved_with_error".localized) \(error.localizedDescription)"
                            )
                        }
                    )
                    .store(in: &self.cancellable)
            }
        )
    }
}

// MARK: - UIDocumentPickerDelegate

extension MessageViewController: UIDocumentPickerDelegate {
    public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {

        guard let savedUrl = urls.first,
              let sharedDocumentUrl = savedUrl.sharedDocumentURL else {
            return
        }
        showFileSharedAlert(with: sharedDocumentUrl)
    }

    private func showFileSharedAlert(with url: URL) {
        let alert = UIAlertController(
            title: "message_attachment_saved_successfully_title".localized,
            message: "message_attachment_saved_successfully_message".localized,
            preferredStyle: .alert
        )

        let cancel = UIAlertAction(title: "cancel".localized, style: .cancel) { _ in }
        let open = UIAlertAction(title: "open".localized, style: .default) { _ in
            UIApplication.shared.open(url)
        }

        alert.addAction(cancel)
        alert.addAction(open)

        present(alert, animated: true)
    }
}
