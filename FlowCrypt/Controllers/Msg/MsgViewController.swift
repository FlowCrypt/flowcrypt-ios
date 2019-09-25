//
// © 2017-2019 FlowCrypt Limited. All rights reserved.
//

import UIKit
import MBProgressHUD
import RealmSwift
import Promises

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
        case delete, archive, markAsRead

        var text: String? {
            switch self {
                case .delete: return Language.moved_to_trash
                case .archive: return Language.email_archived
                case .markAsRead: return nil
            }
        }

        var error: String? {
            switch self {
                case .delete: return Constants.ErrorTexts.Message.delete
                case .archive: return Constants.ErrorTexts.Message.archive
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
        let buttons = input?.path == MailDestination.Gmail.trash.path
            ? [infoInput, archiveInput, mailInput]
            : [infoInput, archiveInput, trashInput, mailInput]
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
        showSpinner(Language.loading, isUserInteractionEnabled: true)
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
            showAlert(error: error, message: Language.could_not_open_message + "\n\n\(error)")
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

    private func handleSuccesMessage(operation: MessageAction) {
        guard let input = input else { return }
        hideSpinner()
        operation.text.flatMap { showToast($0) }
        updateCompletion?(operation, input.objMessage)
        navigationController?.popViewController(animated: true)
    }

    private func handleErrorOnMessage(operation: MessageAction) {
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
        imap.moveMsg(msg: input.objMessage, folder: input.path, destFolder: MailDestination.Gmail.trash.path)
            .then(on: .main) { [weak self] _ in
                self?.handleSuccesMessage(operation: .delete)
            }
            .catch(on: .main) { [weak self] error in
                self?.handleErrorOnMessage(operation: .delete)
            }
    }

    @objc private func handleArchiveTap() {
        guard let input = input else { return }
        showSpinner()
        input.objMessage.flags = MCOMessageFlag.deleted
        imap.pushUpdatedMsgFlags(msg: input.objMessage, folder: input.path)
            .then(on: .main) { [weak self] _ in
                self?.handleSuccesMessage(operation: .archive)
            }
            .catch(on: .main) { [weak self] error in
                self?.handleErrorOnMessage(operation: .archive)
            }
    }

    @IBAction private func handleReplyTap(_ sender: UIButton) {
        guard let input = input else { return }
        let viewModel = ComposeViewController.Input(
            isReply: true,
            replyToRecipient: input.objMessage.header.from,
            replyToSubject: input.objMessage.header.subject,
            replyToMime: input.bodyMessage
        )
        let replyVc = ComposeViewController.instance(with: viewModel)
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
