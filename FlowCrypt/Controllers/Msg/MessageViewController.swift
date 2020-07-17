//
// © 2017-2019 FlowCrypt Limited. All rights reserved.
//

import AsyncDisplayKit
import FlowCryptUI
import Promises

final class MessageViewController: ASViewController<TableNode> {
    struct Input {
        var objMessage = MCOIMAPMessage()
        var bodyMessage: Data?
        var path = ""
    }

    enum Parts: Int, CaseIterable {
        case sender, subject, text

        var indexPath: IndexPath {
            IndexPath(row: rawValue, section: 0)
        }
    }

    enum MessageAction {
        case moveToTrash, archive, markAsRead, permanentlyDelete

        var text: String? {
            switch self {
            case .moveToTrash: return "email_removed".localized
            case .archive: return "email_archived".localized
            case .permanentlyDelete: return "email_deleted".localized
            case .markAsRead: return nil
            }
        }

        var error: String? {
            switch self {
            case .moveToTrash: return "error_move_trash".localized
            case .archive: return "error_archive".localized
            case .permanentlyDelete: return "error_permanently_delete".localized
            case .markAsRead: return nil
            }
        }
    }

    typealias MsgViewControllerCompletion = (MessageAction, MCOIMAPMessage) -> Void
    private let onCompletion: MsgViewControllerCompletion?
    private var input: MessageViewController.Input?
    private let imap: Imap
    private let decorator: MessageViewDecoratorType
    private var dataService: DataServiceType & KeyDataServiceType
    private let core: Core

    private var message: NSAttributedString

    init(
        imap: Imap = Imap.shared,
        decorator: MessageViewDecoratorType = MessageViewDecorator(dateFormatter: DateFormatter()),
        storage: DataServiceType & KeyDataServiceType = DataService.shared,
        core: Core = Core.shared,
        input: MessageViewController.Input,
        completion: MsgViewControllerCompletion?
    ) {
        self.imap = imap
        self.input = input
        self.decorator = decorator
        self.dataService = storage
        self.core = core
        onCompletion = completion
        message = decorator.attributed(
            text: "loading_title".localized + "...",
            color: .lightGray
        )

        super.init(node: TableNode())
    }

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
        imap.trashFolderPath()
            .then(on: .main) { [weak self] path in
                self?.setupNavigationBarItems(with: path)
            }
    }

    private func setupNavigationBarItems(with trashFolderPath: String?) {
        let helpButton = NavigationBarItemsView.Input(image: UIImage(named: "help_icn"), action: (self, #selector(handleInfoTap)))
        let archiveButton = NavigationBarItemsView.Input(image: UIImage(named: "archive"), action: (self, #selector(handleArchiveTap)))
        let trashButton = NavigationBarItemsView.Input(image: UIImage(named: "trash"), action: (self, #selector(handleTrashTap)))
        let unreadButton = NavigationBarItemsView.Input(image: UIImage(named: "mail"), action: (self, #selector(handleMailTap)))

        let items: [NavigationBarItemsView.Input]
        switch input?.path.lowercased() {
        case trashFolderPath?.lowercased():
            // in case we are in trash folder ([Gmail]/Trash or Deleted for Outlook, etc)
            // we need to have only help and trash buttons
            items = [helpButton, trashButton]
        case MailDestination.Gmail.inbox.path.lowercased():
            // for Gmail inbox we also need to have archive and unread buttons
            items = [helpButton, archiveButton, trashButton, unreadButton]
        default:
            // in any other folders
            items = [helpButton, trashButton, unreadButton]
        }

        navigationItem.rightBarButtonItem = NavigationBarItemsView(with: items)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard #available(iOS 13.0, *) else { return }
        node.reloadData()
    }
}

// MARK: - Message

extension MessageViewController {
    private func fetchDecryptAndRenderMsg() {
        guard let input = input else { return }
        showSpinner("loading_title".localized, isUserInteractionEnabled: true)
        Promise { [weak self] in
            self?.message = try await(self!.fetchMessage())
        }.then(on: .main) { [weak self] in
            self?.hideSpinner()
            self?.node.reloadRows(at: [Parts.text.indexPath], with: .fade)
            self?.asyncMarkAsReadIfNotAlreadyMarked()
        }.catch(on: .main) { [weak self] error in
            self?.hideSpinner()
            self?.handleError(error, path: input.path)
        }
    }

    private func fetchMessage() -> Promise<NSAttributedString> {
        Promise { [weak self] resolve, reject in
            guard let self = self, let input = self.input else { return }
            let rawMimeData = try await(self.imap.fetchMsg(message: input.objMessage, folder: input.path))
            self.input?.bodyMessage = rawMimeData

            guard let keys = self.dataService.keys else {
                reject(CoreError.notReady("Could not fetch keys"))
                return
            }

            let decrypted = try self.core.parseDecryptMsg(
                encrypted: rawMimeData,
                keys: keys,
                msgPwd: nil,
                isEmail: true
            )
            let decryptErrBlocks = decrypted.blocks.filter { $0.decryptErr != nil }

            let message: NSAttributedString
            if let decryptErrBlock = decryptErrBlocks.first {
                let rawMsg = decryptErrBlock.content
                let err = decryptErrBlock.decryptErr?.error
                message = self.decorator.attributed(
                    text: "Could not decrypt:\n\(err?.type.rawValue ?? "UNKNOWN"): \(err?.message ?? "??")\n\n\n\(rawMsg)",
                    color: .red
                )
            } else {
                message = self.decorator.attributed(
                    text: decrypted.text,
                    color: decrypted.replyType == CoreRes.ReplyType.encrypted ? .main : UIColor.mainTextColor
                )
            }
            resolve(message)
        }
    }

    private func handleError(_ error: Error, path: String) {
        if let someError = error as NSError?, someError.code == Imap.Err.fetch.rawValue {
            // todo - the missing msg should be removed from the list in inbox view
            // reproduce: 1) load inbox 2) move msg to trash on another email client 3) open trashed message in inbox
            showToast("Message not found in folder: \(path)")
        } else {
            // todo - this should be a retry / cancel alert
            showAlert(error: error, message: "message_failed_open".localized + "\n\n\(error)")
        }
        navigationController?.popViewController(animated: true)
    }

    private func asyncMarkAsReadIfNotAlreadyMarked() {
        guard let input = input else { return }
        guard !input.objMessage.flags.isSuperset(of: MCOMessageFlag.seen) else { return } // only proceed if not already marked as read
        input.objMessage.flags.formUnion(MCOMessageFlag.seen)
        imap.markAsRead(message: input.objMessage, folder: input.path)
            .catch(on: .main) { [weak self] error in
                self?.showToast("Could not mark message as read: \(error)")
            }
    }

    private func handleOpSuccess(operation: MessageAction) {
        guard let input = input else { return }
        hideSpinner()
        operation.text.flatMap { showToast($0) }

        navigationController?.popViewController(animated: true) { [weak self] in
            self?.onCompletion?(operation, input.objMessage)
        }
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

    @objc private func handleMailTap() {
        showToast("Marking as unread will be implemented soon")
    }

    @objc private func handleTrashTap() {
        showSpinner()

        imap.trashFolderPath()
            .then { [weak self] trashPath in
                guard let strongSelf = self, let input = strongSelf.input, let path = trashPath else {
                    self?.permanentlyDelete()
                    return
                }

                input.path == trashPath
                    ? strongSelf.permanentlyDelete()
                    : strongSelf.moveToTrash(with: path)
            }
            .catch(on: .main) { error in
                self.showToast(error.localizedDescription)
            }
    }

    private func permanentlyDelete() {
        guard let input = input else { return hideSpinner() }
        input.objMessage.flags = MCOMessageFlag(rawValue: input.objMessage.flags.rawValue | MCOMessageFlag.deleted.rawValue)

        Promise<Bool> { [weak self] () -> Bool in
            guard let self = self else { throw AppErr.nilSelf }
            guard try await(self.awaitUserConfirmation(title: "You're about to permanently delete a message")) else { return false }

            input.objMessage.flags = MCOMessageFlag(rawValue: input.objMessage.flags.rawValue | MCOMessageFlag.deleted.rawValue)
            try await(self.imap.pushUpdatedMsgFlags(msg: input.objMessage, folder: input.path))
            try await(self.imap.expungeMsgs(folder: input.path))
            return true
        }
        .then(on: .main) { [weak self] didPerformOp in
            guard didPerformOp else { self?.hideSpinner(); return  }
            self?.handleOpSuccess(operation: .permanentlyDelete)
        }.catch(on: .main) { [weak self] _ in
            self?.handleOpErr(operation: .permanentlyDelete)
        }
    }

    private func moveToTrash(with trashPath: String) {
        guard let input = input else { return hideSpinner() }

        imap.moveMsg(msg: input.objMessage, folder: input.path, destFolder: trashPath)
            .then(on: .main) { [weak self] in
                self?.handleOpSuccess(operation: .moveToTrash)
            }
            .catch(on: .main) { [weak self] _ in
                self?.handleOpErr(operation: .moveToTrash)
            }
    }

    @objc private func handleArchiveTap() {
        guard let input = input else { return }
        showSpinner()
        input.objMessage.flags = MCOMessageFlag(rawValue: input.objMessage.flags.rawValue | MCOMessageFlag.deleted.rawValue)
        imap.pushUpdatedMsgFlags(msg: input.objMessage, folder: input.path)
            .then(on: .main) { [weak self] _ in
                self?.handleOpSuccess(operation: .archive)
            }
            .catch(on: .main) { [weak self] _ in // todo - specific error should be toasted or shown
                self?.handleOpErr(operation: .archive)
            }
    }

    private func handleReplyTap() {
        guard let input = input else { return }
        let replyInfo = ComposeViewController.Input.ReplyInfo(
            recipient: input.objMessage.header.from,
            subject: input.objMessage.header.subject,
            mime: input.bodyMessage,
            sentDate: input.objMessage.header.date,
            message: message.string
        )

        navigationController?.pushViewController(
            ComposeViewController(
                input: ComposeViewController.Input(
                    type: .reply(replyInfo)
                )
            ),
            animated: true
        )
    }
}

// MARK: - NavigationChildController

extension MessageViewController: NavigationChildController {
    func handleBackButtonTap() {
        guard let message = input?.objMessage else { return }
        onCompletion?(MessageAction.markAsRead, message)
        navigationController?.popViewController(animated: true)
    }
}

// MARK: - ASTableDelegate, ASTableDataSource

extension MessageViewController: ASTableDelegate, ASTableDataSource {
    func tableNode(_: ASTableNode, numberOfRowsInSection _: Int) -> Int {
        return Parts.allCases.count
    }

    func tableNode(_ tableNode: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        // TODO: ANTON - input?.objMessage.header.sender.mailbox ?? "(unknown sender)"
        // crash because sender is nil

        let senderTitle = decorator.attributed(
            title: input?.objMessage.header.from.mailbox ?? "(unknown sender)"
        )
        let subject = decorator.attributed(
            subject: input?.objMessage.header.subject ?? "(no subject)"
        )
        let time = decorator.attributed(
            date: input?.objMessage.header.date
        )

        return { [weak self] in
            guard let self = self, let part = Parts(rawValue: indexPath.row) else { return ASCellNode() }
            switch part {
            case .sender:
                return MessageSenderNode(senderTitle) { [weak self] in
                    self?.handleReplyTap()
                }
            case .subject:
                return MessageSubjectNode(subject, time: time)
            case .text:
                return MessageTextSubjectNode(self.message)
            }
        }
    }
}
