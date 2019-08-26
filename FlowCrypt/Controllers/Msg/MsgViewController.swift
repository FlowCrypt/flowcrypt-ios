//
// © 2017-2019 FlowCrypt Limited. All rights reserved.
//

import UIKit
import MBProgressHUD
import RealmSwift
import Promises

protocol MsgViewControllerDelegate: class {
    func movedOrUpdated(objMessage: MCOIMAPMessage)
}

extension MsgViewController {
    static func instance(with input: MsgViewController.Input, delegate: MsgViewControllerDelegate?) -> MsgViewController {
        let vc = UIStoryboard.main.instantiate(MsgViewController.self)
        vc.input = input
        vc.delegate = delegate
        return vc
    }
}

final class MsgViewController: UIViewController {
    struct Input {
        var objMessage = MCOIMAPMessage()
        var bodyMessage: Data?
        var path = ""
    }

    private enum MessageAction {
        case delete, archive

        var text: String {
            switch self {
            case .delete: return Language.moved_to_trash
            case .archive: return Language.email_archived
            }
        }

        var error: String {
            switch self {
            case .delete: return Constants.ErrorTexts.Message.delete
            case .archive: return Constants.ErrorTexts.Message.archive
            }
        }
    }

    @IBOutlet var lblSender: UILabel!
    @IBOutlet var lblSubject: UILabel!
    @IBOutlet var lblTIme: UILabel!
    @IBOutlet var lblBody: UILabel!
    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var scrollViewContent: UIView!

    // TODO: Inject as a dependency
    private let imap = Imap.instance
    private var input: MsgViewController.Input?

    weak var delegate: MsgViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigationBar()
        fetchMessage()
    }

    private func setupUI() {
        lblSender.text = input?.objMessage.header.sender.mailbox ?? "(unknown sender)"
        lblSubject.text = input?.objMessage.header.subject ?? "(no subject)"
        lblBody.numberOfLines = 0
        lblTIme.text = ""
        if let date = input?.objMessage.header.date {
            lblTIme.text = Constants.convertDate(date: date)
        }
    }

    private func setupNavigationBar() {
        let infoInput = NavigationBarItemsView.Input(
            image: UIImage(named: "help_icn"),
            action: (self, #selector(handleInfoTap))
        )

        let archiveInput = NavigationBarItemsView.Input(
            image: UIImage(named: "archive"),
            action: (self, #selector(handleArchiveTap))
        )

        let trashInput = NavigationBarItemsView.Input(
            image: UIImage(named: "trash"),
            action: (self, #selector(handleTrashTap))
        )

        let mailInput = NavigationBarItemsView.Input(
            image: UIImage(named: "mail"),
            action: (self, #selector(handleMailTap))
        )

        let buttons = input?.path == MailDestination.Gmail.trash.path
            ? [infoInput, archiveInput, mailInput]
            : [infoInput, archiveInput, trashInput, mailInput]

        navigationItem.rightBarButtonItem = NavigationBarItemsView(with: buttons)
    }

    private func renderMsgBody(_ text: String, color: UIColor = UIColor.black) {
        lblBody.text = text
        lblBody.textColor = color
        lblBody.sizeToFit()
        scrollView.contentSize = scrollViewContent.frame.size
    }
}

// MARK: - Message
extension MsgViewController {
    private func fetchMessage() {
        guard let input = input else { return }
        showSpinner(Language.loading, isUserInteractionEnabled: true)

        imap.fetchMsg(message: input.objMessage, folder: input.path)
            .then(on: .main) { [weak self] data in
                guard let self = self else { throw ImapError.general }
                self.input?.bodyMessage = data
                let realm = try Realm()
                let decrypted = try Core.parseDecryptMsg(
                    encrypted: data,
                    keys: PrvKeyInfo.from(realm: realm.objects(KeyInfo.self)),
                    msgPwd: nil,
                    isEmail: true
                )
                self.handleDecryptedMsg(decrypted)
            }
            .catch(on: .main) { [weak self] error in
                self?.hideSpinner()
                self?.showAlert(error: error, message: Language.could_not_open_message)
            }
    }


    private func handleDecryptedMsg(_ decrypted: CoreRes.ParseDecryptMsg) {
        let decryptErrBlocks = decrypted.blocks.filter { $0.decryptErr != nil }
        if let decryptErrBlock = decryptErrBlocks.first {
            let rawMsg = decryptErrBlock.content
            let err = decryptErrBlock.decryptErr?.error
            renderMsgBody(
                "Dould not decrypt message:\n\(err?.type.rawValue ?? "UNKNOWN"): \(err?.message ?? "??")\n\n\n\(rawMsg)",
                color: .red
            )
        } else {
            renderMsgBody(
                decrypted.text,
                color: decrypted.replyType == CoreRes.ReplyType.encrypted ? Constants.green : UIColor.black
            )
        }
        markAsReadIfNotAlreadyMarked()
        hideSpinner()
    }

    private func markAsReadIfNotAlreadyMarked() {
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
        delegate?.movedOrUpdated(objMessage: input.objMessage)
        showToast(operation.text)
        navigationController?.popViewController(animated: true)
    }

    private func handleErrorOnMessage(operation: MessageAction) {
        hideSpinner()
        showToast(operation.error)
    }
}

// MARK: - Handle Actions
extension MsgViewController {
    @objc private func handleInfoTap() {
        showToast("Info not implemented yet")
    }

    @objc private func handleMailTap() {
        showToast("Not implemented yet")
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
