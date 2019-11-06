//
// © 2017-2019 FlowCrypt Limited. All rights reserved.
//

import Promises
import AsyncDisplayKit

final class MsgViewController: ASViewController<ASTableNode> {
    typealias MsgViewControllerCompletion = (MessageAction, MCOIMAPMessage) -> Void
    private let onCompletion: MsgViewControllerCompletion?
    private var input: MsgViewController.Input?
    private let imap: Imap
    private let decorator: MessageDecoratorType
    private let storage: StorageServiceType
    private var message: NSAttributedString?

    init(
        imap: Imap = Imap.instance,
        decorator: MessageDecoratorType = MessageDecorator(dateFormatter: DateFormatter()),
        storage: StorageServiceType = StorageService(),
        input: MsgViewController.Input,
        completion: MsgViewControllerCompletion?
    ) {
        self.imap = imap
        self.input = input
        self.decorator = decorator
        self.storage = storage
        self.onCompletion = completion
        super.init(node: TableNode())
    }

    required init?(coder: NSCoder) {
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
        let infoInput = NavigationBarItemsView.Input(image: UIImage(named: "help_icn"), action: (self, #selector(handleInfoTap)))
        let archiveInput = NavigationBarItemsView.Input(image: UIImage(named: "archive"), action: (self, #selector(handleArchiveTap)))
        let trashInput = NavigationBarItemsView.Input(image: UIImage(named: "trash"), action: (self, #selector(handleTrashTap)))
        let mailInput = NavigationBarItemsView.Input(image: UIImage(named: "mail"), action: (self, #selector(handleMailTap)))
        let buttons: [NavigationBarItemsView.Input]
        switch input?.path {
        case MailDestination.Gmail.trash.path: buttons = [infoInput, trashInput]
        case MailDestination.Gmail.inbox.path: buttons = [infoInput, archiveInput, trashInput, mailInput]
        default: buttons = [infoInput, trashInput, mailInput]
        }
        navigationItem.rightBarButtonItem = NavigationBarItemsView(with: buttons)
    }
}

// MARK: - Message

extension MsgViewController {
    private func fetchDecryptAndRenderMsg() {
        guard let input = input else { return }
        showSpinner("loading_title".localized, isUserInteractionEnabled: true)
        Promise { [weak self] in
            self?.message = try await(self!.fetchMessage())
        }.then(on: .main) { [weak self]  in
            self?.hideSpinner()
            self?.node.reloadRows(at: [Parts.text.indexPath], with: .fade)
            self?.asyncMarkAsReadIfNotAlreadyMarked()
        }.catch(on: .main) { [weak self] error in
            self?.hideSpinner()
            self?.handleError(error, path: input.path)
        }
    }

    private func fetchMessage() -> Promise<NSAttributedString> {
        return Promise { [weak self] resolve, reject in
            guard let self = self, let input = self.input else { return }
            let rawMimeData = try await(self.imap.fetchMsg(message: input.objMessage, folder: input.path))
            self.input?.bodyMessage = rawMimeData
            let keys = self.storage.keys()

            let decrypted = try Core.parseDecryptMsg(
                encrypted: rawMimeData,
                keys: PrvKeyInfo.from(realm: keys),
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
                    color: decrypted.replyType == CoreRes.ReplyType.encrypted ? .main : UIColor.black
                )
            }
            resolve(message)
        }
    }

    private func handleError(_ error: Error, path: String) {
        if let e = error as NSError?, e.code == Imap.Err.fetch.rawValue {
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

extension MsgViewController {
    @objc private func handleInfoTap() {
        showToast("Email us at human@flowcrypt.com")
    }

    @objc private func handleMailTap() {
        showToast("Marking as unread will be implemented soon")
    }

    @objc private func handleTrashTap() {
        guard let input = input else { return }
        showSpinner()
        let op = input.path != MailDestination.Gmail.trash.path ? MessageAction.moveToTrash : MessageAction.permanentlyDelete
        Promise<Bool> { [weak self] () -> Bool in
            guard let self = self else { throw AppErr.nilSelf }
            if op == MessageAction.permanentlyDelete {
                input.objMessage.flags = MCOMessageFlag(rawValue: input.objMessage.flags.rawValue | MCOMessageFlag.deleted.rawValue)
                guard try await(self.awaitUserConfirmation(title: "You're about to permanently delete a message")) else { return false }
                try await(self.imap.pushUpdatedMsgFlags(msg: input.objMessage, folder: input.path))
                try await(self.imap.expungeMsgs(folder: input.path))
            } else {
                try await(self.imap.moveMsg(msg: input.objMessage, folder: input.path, destFolder: MailDestination.Gmail.trash.path))
            }
            return true
        }.then(on: .main) { [weak self] didPerformOp in
            if didPerformOp {
                self?.handleOpSuccess(operation: op)
            } else {
                self?.hideSpinner()
            }
        }.catch(on: .main) { [weak self] _ in
            self?.handleOpErr(operation: op)
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
        let viewModel = ComposeViewController.Input(
            isReply: true,
            replyToRecipient: input.objMessage.header.from,
            replyToSubject: input.objMessage.header.subject,
            replyToMime: input.bodyMessage
        )
        let replyVc = ComposeViewController(input: viewModel)
        navigationController?.pushViewController(replyVc, animated: true)
    }
}

// MARK: - NavigationChildController

extension MsgViewController: NavigationChildController {
    func handleBackButtonTap() {
        guard let message = input?.objMessage else { return }
        onCompletion?(MessageAction.markAsRead, message)
        navigationController?.popViewController(animated: true)
    }
}

// MARK: - ASTableDelegate, ASTableDataSource

extension MsgViewController: ASTableDelegate, ASTableDataSource {
    func tableNode(_ tableNode: ASTableNode, numberOfRowsInSection section: Int) -> Int {
        return Parts.allCases.count
    }

    func tableNode(_ tableNode: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        let senderTitle = decorator.attributed(
            title: input?.objMessage.header.sender.mailbox ?? "(unknown sender)"
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
                return TextSubjectNode(self.message)
            }
        }
    }
}
