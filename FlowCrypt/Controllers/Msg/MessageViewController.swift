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
    private let messageOperationsProvider: MessageOperationsProvider
    private let filesManager: FilesManagerType
    private var processedMessage: ProcessedMessage = .empty

    let trashFolderProvider: TrashFolderProviderType
    var currentFolderPath: String {
        input.path
    }

    init(
        messageService: MessageService = MessageService(),
        messageOperationsProvider: MessageOperationsProvider = MailProvider.shared.messageOperationsProvider,
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
        showSpinner("loading_title".localized, isUserInteractionEnabled: true)

        Promise { [weak self] in
            guard let self = self else { return }
            let promise = self.messageService.getAndProcessMessage(
                with: self.input.objMessage,
                folder: self.input.path
            )
            let message = try awaitPromise(promise)
            self.processedMessage = message
        }
        .then(on: .main) { [weak self] in
            self?.handleReceivedMessage()
        }
        .catch(on: .main) { [weak self] error in
            self?.handleError(error)
        }
    }

    private func validateMessage(rawMimeData: Data, with passPhrase: String) {
        showSpinner("loading_title".localized, isUserInteractionEnabled: true)

        messageService.validateMessage(rawMimeData: rawMimeData, with: passPhrase)
            .then(on: .main) { [weak self] message in
                self?.processedMessage = message
                self?.handleReceivedMessage()
            }
            .catch(on: .main) { [weak self] error in
                self?.handleError(error)
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
        case let .missedPassPhrase(rawMimeData):
            handleMissedPassPhrase(for: rawMimeData)
        case let .wrongPassPhrase(rawMimeData, passPhrase):
            handleWrongPathPhrase(for: rawMimeData, with: passPhrase)
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

    private func handleMissedPassPhrase(for rawMimeData: Data) {
        let alert = AlertsFactory.makePassPhraseAlert(
            onCancel: { [weak self] in
                self?.navigationController?.popViewController(animated: true)
            },
            onCompletion: { [weak self] passPhrase in
                self?.validateMessage(rawMimeData: rawMimeData, with: passPhrase)
            })

        present(alert, animated: true, completion: nil)
    }

    private func handleWrongPathPhrase(for rawMimeData: Data, with phrase: String) {
        let alert = AlertsFactory.makeWrongPassPhraseAlert(
            onCancel: { [weak self] in
                self?.navigationController?.popViewController(animated: true)
            },
            onCompletion: { [weak self] passPhrase in
                self?.validateMessage(rawMimeData: rawMimeData, with: passPhrase)
            })
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

    func handleTrashTap() {
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

    func handleArchiveTap() {
        showSpinner()
        messageOperationsProvider.archiveMessage(message: input.objMessage, folderPath: input.path)
            .then(on: .main) { [weak self] _ in
                self?.handleOpSuccess(operation: .archive)
            }
            .catch(on: .main) { [weak self] _ in // todo - specific error should be toasted or shown
                self?.handleOpErr(operation: .archive)
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
            return MessageTextSubjectNode(self.processedMessage.attributedMessage)
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
