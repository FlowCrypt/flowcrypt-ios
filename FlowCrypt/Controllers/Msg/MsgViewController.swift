//
// © 2017-2019 FlowCrypt Limited. All rights reserved.
//

import MBProgressHUD
import Promises
import RealmSwift
import UIKit

extension MsgViewController {
    static func instance(with input: MsgViewController.Input, completion: MsgViewControllerCompletion?) -> MsgViewController {
        let vc = UIStoryboard.main.instantiate(MsgViewController.self)
        vc.updateCompletion = completion
        vc.input = input
        return vc
    }
}

final class MsgViewController: UIViewController {
    struct Input {
        var objMessage = MCOIMAPMessage()
        var bodyMessage: Data?
        var path = ""
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
    private var updateCompletion: MsgViewControllerCompletion?

    @IBOutlet var lblSender: UILabel!
    @IBOutlet var lblSubject: UILabel!
    @IBOutlet var lblTIme: UILabel!
    @IBOutlet var lblBody: UILabel!
    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var scrollViewContent: UIView!

    // TODO: Inject as a dependency
    private let imap = Imap.instance
    private var input: MsgViewController.Input?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigationBar()
        fetchDecryptAndRenderMsg()
    }

    private func setupUI() {
        lblSender.text = input?.objMessage.header.sender.mailbox ?? "(unknown sender)"
        lblSubject.text = input?.objMessage.header.subject ?? "(no subject)"
        lblBody.numberOfLines = 0
        lblTIme.text = ""
        if let date = input?.objMessage.header.date {
            lblTIme.text = DateFormatter().formatDate(date)
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

    private func renderBody(_ text: String, color: UIColor = UIColor.black) {
        lblBody.text = text
        lblBody.textColor = color
        lblBody.sizeToFit()
        scrollView.contentSize = scrollViewContent.frame.size
    }
}

// MARK: - Message

extension MsgViewController {
    private func fetchDecryptAndRenderMsg() {
        guard let input = input else { return }
        showSpinner("loading_title".localized, isUserInteractionEnabled: true)
        Promise { [weak self] in
            guard let self = self else { return }
            let rawMimeData = try await(self.imap.fetchMsg(message: input.objMessage, folder: input.path))
            self.input?.bodyMessage = rawMimeData
            let decrypted = try Core.parseDecryptMsg(
                encrypted: rawMimeData,
                keys: PrvKeyInfo.from(realm: try Realm().objects(KeyInfo.self)),
                msgPwd: nil,
                isEmail: true
            )
            self.renderMsgOnMain(decrypted)
            self.asyncMarkAsReadIfNotAlreadyMarked()
        }.then(on: .main) { [weak self] in
            self?.hideSpinner()
        }.catch(on: .main) { [weak self] error in
            self?.hideSpinner()
            self?.handleError(error, path: input.path)
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

    private func renderMsgOnMain(_ msg: CoreRes.ParseDecryptMsg) {
        DispatchQueue.main.async { [weak self] in
            let decryptErrBlocks = msg.blocks.filter { $0.decryptErr != nil }
            if let decryptErrBlock = decryptErrBlocks.first {
                let rawMsg = decryptErrBlock.content
                let err = decryptErrBlock.decryptErr?.error
                self?.renderBody("Could not decrypt:\n\(err?.type.rawValue ?? "UNKNOWN"): \(err?.message ?? "??")\n\n\n\(rawMsg)", color: .red)
            } else {
                self?.renderBody(msg.text, color: msg.replyType == CoreRes.ReplyType.encrypted ? .main : UIColor.black)
            }
        }
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
            self?.updateCompletion?(operation, input.objMessage)
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

    @IBAction private func handleReplyTap(_: UIButton) {
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

extension MsgViewController: NavigationChildController {
    func handleBackButtonTap() {
        guard let message = input?.objMessage else { return }
        updateCompletion?(MessageAction.markAsRead, message)
        navigationController?.popViewController(animated: true)
    }
}
